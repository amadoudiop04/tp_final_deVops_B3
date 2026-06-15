# Journal de déploiement — ShopLite

## Environnements

| Env | Branche / Tag | Port | URL |
|---|---|---|---|
| Staging | `Dev` (auto) | 8081 | http://localhost:8081 |
| Production | tag `v*` (manuel) | 8080 | http://localhost:8080 |

---

## Gestion du risque de livraison

### 1. Comparer version stable et version modifiée

Avant de livrer une nouvelle version, on compare ce qui a changé entre la version stable et la nouvelle :

```sh
./scripts/compare-versions.sh v1.0.0 v1.1.0
```

Ce script affiche :
- Les fichiers modifiés entre les deux tags Git
- Les commits ajoutés dans la nouvelle version
- Les images Docker des deux versions côte à côte (taille, SHA, date de build)

---

### 2. Redéploiement simple

Relancer une version spécifique en staging ou production :

```sh
# Staging
sh scripts/deploy-staging.sh v1.1.0

# Production
sh scripts/deploy-production.sh v1.1.0
```

Ces scripts font un `docker compose up -d --build` avec la version choisie, attendent que le health check passe, puis lancent un smoke test automatique.

---

### 3. Modification SQL non destructive

Le fichier `database/migration_v1.1.0.sql` ajoute une colonne `stock` et un nouveau produit **sans supprimer ni modifier les données existantes** :

- `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` : la colonne est ajoutée uniquement si elle n'existe pas déjà, les produits existants reçoivent la valeur par défaut `100`
- `INSERT ... ON CONFLICT DO NOTHING` : aucun produit existant n'est écrasé

Pour appliquer la migration :

```sh
psql -h localhost -U shoplite -d shoplite -f database/migration_v1.1.0.sql
```

---

### 4. Plan de retour arrière

Si la nouvelle version échoue après déploiement, voici les commandes exactes pour revenir à la version stable :

```sh
# Étape 1 — voir les versions disponibles localement
docker images shoplite-api

# Étape 2 — rollback vers la version stable (ex: v1.0.0)
sh scripts/rollback.sh v1.0.0

# Rollback en staging si besoin
sh scripts/rollback.sh v1.0.0 staging
```

Le script `rollback.sh` :
1. Arrête la stack en cours
2. Redémarre avec la version stable
3. Attend que le health check passe
4. Lance un smoke test pour confirmer que tout fonctionne

---

## Procédures locales

### Déployer en staging

```sh
sh scripts/deploy-staging.sh
```

### Déployer en production

```sh
sh scripts/deploy-production.sh v1.0.0
```

### Rollback

```sh
sh scripts/rollback.sh v1.0.0
```

---

## Validation avant production

L'environnement GitHub **prod** est configuré avec des *Required reviewers*.
Le job `deploy-production` se met en pause et attend l'approbation d'un reviewer avant de déployer.

---

## Registre des déploiements

| Version | Date | Auteur | Environnement | Résultat |
|---|---|---|---|---|
| v0.1.0 | 2026-06-11 | AMADOU | staging | ✅ succès |
