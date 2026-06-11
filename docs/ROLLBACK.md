# Rollback — ShopLite

| # | Notion | Script / Fichier |
|---|--------|-----------------|
| 1 | Sauvegarder logs avant | `scripts/rollback.sh` — exporte `docker logs` dans `logs/incident_TIMESTAMP.log` |
| 2 | Identifier version actuelle | `scripts/diagnose.sh` — `docker inspect` sur les labels de l'image |
| 3 | Vérifier image stable dispo | `scripts/rollback.sh` — `docker image inspect shoplite-api:<version>` |
| 4 | `rollback.sh` réutilisable | `scripts/rollback.sh <version> [staging\|production]` |
| 5 | Rollback par image taguée | `scripts/rollback.sh` — `APP_VERSION=$TARGET docker compose up -d` |
| 6 | Vérification post-rollback | `scripts/rollback.sh` — smoke test + count produits via API |
| 7 | Communication intégrée | `scripts/rollback.sh` — génère `docs/incidents/incident_TIMESTAMP.md` |

---

## Scripts

### `scripts/rollback.sh` — Script principal (7 notions)

```sh
sh scripts/rollback.sh v1.0.0             # rollback production
sh scripts/rollback.sh v1.0.0 staging     # rollback staging
```

Enchaîne automatiquement les 7 étapes : export logs → inspect version → check image → arrêt stack → redémarrage → smoke test → rapport.

### `scripts/diagnose.sh` — Diagnostic rapide

```sh
sh scripts/diagnose.sh            # production
sh scripts/diagnose.sh staging    # staging
```

Affiche : version déployée (`docker inspect`), images disponibles, état conteneurs, derniers logs API, derniers commits Git, smoke test.

### `scripts/incident-scenario.sh` — Scénario complet

```sh
sh scripts/incident-scenario.sh v1.0.0
```

Rejoue les 9 étapes du scénario obligatoire de manière automatisée.

---

## Scénario obligatoire

| Étape | Action | Résultat attendu |
|-------|--------|-----------------|
| 1 | Stack démarrée, CI verte | Service opérationnel |
| 2 | `sh scripts/backup.sh` | Dump PostgreSQL créé dans `backups/` |
| 3 | Version stable identifiée | `docker images shoplite-api` |
| 4 | `GET /api/products` | PASS — `source: database` |
| 5 | `DROP TABLE products` dans le conteneur | Incident actif |
| 6 | `GET /api/products` | FAIL — HTTP 500 |
| 7 | `sh scripts/diagnose.sh` | Logs exportés, cause identifiée |
| 8 | `sh scripts/rollback.sh v1.0.0` | Stack relancée, volumes intacts |
| 9 | `GET /api/products` | PASS — données restaurées |

---

## Contrainte respectée

Le rollback utilise `docker compose down` (sans `-v`).

```sh
# Ce que rollback.sh fait
docker compose down          # ← arrêt propre, volumes nommés préservés

# Ce qui est INTERDIT
docker compose down -v       # ← détruit shoplite_pgdata et toutes les données
```

---

## Rapport d'incident généré automatiquement

Chaque rollback produit un fichier `docs/incidents/incident_TIMESTAMP.md` :

```
## Actions menées
| Étape | Action                        | Résultat         |
|-------|-------------------------------|-----------------|
| 1     | Export des logs API           | logs/incident_… |
| 2     | Version incidentée identifiée | v1.1.0-broken   |
| 3     | Image stable vérifiée         | shoplite-api:v1.0.0 |
| 4     | Stack arrêtée (volumes OK)    | OK               |
| 5     | Rollback vers v1.0.0          | OK               |
| 6     | Smoke test post-rollback      | PASS             |
| 7     | Données PostgreSQL vérifiées  | 5 produit(s)     |
```
