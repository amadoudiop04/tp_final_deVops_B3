# Backup et reprise — ShopLite

## Les 5 notions implémentées

| # | Notion | Fichier / Configuration |
|---|--------|------------------------|
| 1 | `pg_dump` avec nom horodaté | `scripts/backup.sh` |
| 2 | Tester la restauration | `scripts/restore-test.sh` |
| 3 | Volume backup hors container | `docker-compose.yml` — bind mount `./backups:/backups` |
| 4 | Politique de rétention (7 derniers) | `scripts/backup.sh` — section rétention |
| 5 | Backup manuel horodaté | `scripts/backup.sh` — `shoplite_YYYY-MM-DD_HH-MM-SS.sql.gz` |

---

## Architecture de backup

```
Hôte (./backups/)               Conteneur shoplite_db
      │                                    │
      │  ←── bind mount ────────────────── /backups/
      │
      ├── shoplite_2026-06-11_10-30-00.sql.gz   ← le plus récent
      ├── shoplite_2026-06-10_22-00-00.sql.gz
      ├── ...                                    ← 5 autres
      └── .gitkeep                               ← tracé par git
```

Le dossier `./backups/` sur l'hôte est monté en bind mount dans le conteneur PostgreSQL (`/backups`). Les dumps produits à l'intérieur du conteneur sont donc immédiatement disponibles sur l'hôte, **sans** passer par le volume nommé `shoplite_pgdata`.

> **INTERDIT** : `docker compose down -v` supprime le volume nommé `shoplite_pgdata` et toutes les données PostgreSQL avec lui. Ne jamais l'utiliser en production.

---

## 1. Script de backup (`scripts/backup.sh`)

### Ce qu'il fait

1. Calcule un timestamp `YYYY-MM-DD_HH-MM-SS`
2. Exécute `pg_dump` dans le conteneur PostgreSQL via `docker exec`
3. Compresse la sortie avec `gzip` et écrit le fichier dans `./backups/`
4. Affiche la taille du fichier créé
5. Applique la politique de rétention : supprime les plus anciens si > 7 fichiers

### Variables d'environnement

| Variable | Défaut | Description |
|----------|--------|-------------|
| `DB_CONTAINER` | `shoplite_db` | Nom du conteneur PostgreSQL |
| `POSTGRES_DB` | `shoplite` | Nom de la base de données |
| `POSTGRES_USER` | `shoplite` | Utilisateur PostgreSQL |
| `BACKUP_RETENTION` | `7` | Nombre de backups à conserver |

### Utilisation

```bash
# Depuis la racine du projet (Git Bash sur Windows)
sh scripts/backup.sh

# Avec une rétention personnalisée (garder 14 backups)
BACKUP_RETENTION=14 sh scripts/backup.sh
```

### Exemple de sortie

```
=== Backup ShopLite — 2026-06-11_10-30-00 ===
  Conteneur : shoplite_db
  Base      : shoplite
  Fichier   : ./backups/shoplite_2026-06-11_10-30-00.sql.gz
  Taille    : 4.2K
  Sauvegarde créée avec succès.

  Rétention : 8 backup(s) présent(s) / maximum 7
  Suppression de 1 ancien(s) backup(s)...
    Supprimé : ./backups/shoplite_2026-06-04_10-30-00.sql.gz
  Backups conservés : 7 / 7
=== Backup terminé : shoplite_2026-06-11_10-30-00.sql.gz ===
```

---

## 2. Script de restauration de test (`scripts/restore-test.sh`)

### Ce qu'il fait

1. Identifie le backup à tester (argument ou dernier disponible)
2. Supprime la base temporaire `shoplite_restore_test` si elle existe
3. Crée une base temporaire `shoplite_restore_test`
4. Restaure le dump dans cette base via `psql`
5. Valide la restauration (`SELECT count(*) FROM products`)
6. Supprime la base temporaire
7. Retourne le code de sortie 0 (PASS) ou 1 (FAIL)

> La base de production `shoplite` n'est jamais touchée par ce script.

### Utilisation

```bash
# Tester le dernier backup automatiquement
sh scripts/restore-test.sh

# Tester un backup spécifique
sh scripts/restore-test.sh ./backups/shoplite_2026-06-11_10-30-00.sql.gz
```

### Exemple de sortie

```
=== Test de restauration ===
  Fichier   : ./backups/shoplite_2026-06-11_10-30-00.sql.gz
  Base test : shoplite_restore_test
  Conteneur : shoplite_db

[1/4] Suppression de la base temporaire (si elle existe)...
[2/4] Création de la base temporaire : shoplite_restore_test
[3/4] Restauration du dump dans shoplite_restore_test...
[4/4] Validation de la restauration...

  Produits restaurés : 5
  Statut : PASS — restauration validée

[Cleanup] Suppression de la base temporaire shoplite_restore_test...
  Base temporaire supprimée (données de production intactes).

=== Restauration test : PASS ===
```

---

## 3. Volume backup hors container

Le bind mount est déclaré dans [docker-compose.yml](../docker-compose.yml) dans le service `db` :

```yaml
services:
  db:
    volumes:
      - shoplite_pgdata:/var/lib/postgresql/data      # données PostgreSQL (volume nommé)
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
      - ./backups:/backups                             # dossier de backups (bind mount hôte)
```

**Distinction importante :**

| Volume | Type | Supprimé par `down -v` ? | Contenu |
|--------|------|--------------------------|---------|
| `shoplite_pgdata` | Volume nommé Docker | **OUI** | Données PostgreSQL live |
| `./backups` | Bind mount hôte | Non | Fichiers `.sql.gz` de backup |

Le bind mount garantit que les backups survivent à n'importe quelle opération Docker, y compris `docker compose down`.

---

## 4. Politique de rétention

La rétention est gérée automatiquement à chaque exécution de `backup.sh` :

```sh
TOTAL=$(ls -1 "$BACKUP_DIR"/*.sql.gz 2>/dev/null | wc -l | tr -d ' ')

if [ "$TOTAL" -gt "$RETENTION" ]; then
  TO_DELETE=$(( TOTAL - RETENTION ))
  ls -1t "$BACKUP_DIR"/*.sql.gz | tail -n "$TO_DELETE" | while IFS= read -r old_file; do
    rm -f "$old_file"
  done
fi
```

- `ls -1t` trie par date de modification (le plus récent en premier)
- `tail -n N` récupère les N plus anciens
- Par défaut : 7 fichiers conservés (configurable via `BACKUP_RETENTION`)

---

## 5. Format du nom de fichier horodaté

```
shoplite_YYYY-MM-DD_HH-MM-SS.sql.gz
    │         │          │       │
    │         │          │       └── compression gzip
    │         │          └────────── heure locale (HH-MM-SS)
    │         └───────────────────── date (YYYY-MM-DD)
    └─────────────────────────────── préfixe = nom de la base
```

Exemple : `shoplite_2026-06-11_10-30-00.sql.gz`

---

## Procédure de sauvegarde régulière recommandée

```bash
# 1. S'assurer que le stack est démarré
docker compose ps

# 2. Lancer le backup
sh scripts/backup.sh

# 3. Vérifier la restauration
sh scripts/restore-test.sh

# 4. Lister les backups disponibles
ls -lh backups/
```

---

## Contrainte de sécurité des données

Le rollback NE DOIT PAS utiliser `docker compose down -v`.

```bash
# CORRECT — préserve les volumes nommés
docker compose down
docker compose up -d

# INTERDIT — détruit shoplite_pgdata et toutes les données
docker compose down -v   # ← NE JAMAIS UTILISER EN PRODUCTION
```

Voir [DEPLOYMENTS.md](DEPLOYMENTS.md) pour les procédures de rollback complètes.
