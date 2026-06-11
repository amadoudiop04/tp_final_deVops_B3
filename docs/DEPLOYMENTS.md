# Journal de déploiement — ShopLite

## Environnements

| Env | Branche / Tag | Port | Compose | URL |
|---|---|---|---|---|
| Staging | `Dev` (auto) | 8081 | `docker-compose.yml -f docker-compose.staging.yml` | http://localhost:8081 |
| Production | tag `v*` (manuel) | 8080 | `docker-compose.yml` | http://localhost:8080 |

---

## Procédures locales

### Déployer en staging

```sh
# Auto via push sur dev — ou en local :
sh scripts/deploy-staging.sh

# Avec version explicite
APP_VERSION=v1.0.0 sh scripts/deploy-staging.sh
```

### Déployer en production simulée

```sh
# Nécessite un tag v* poussé sur main
sh scripts/deploy-production.sh v1.0.0
```

### Rollback

```sh
# Rollback production vers une version stable
sh scripts/rollback.sh v0.9.0

# Rollback staging
sh scripts/rollback.sh v0.9.0 staging

# Lister les images disponibles
docker images shoplite-api
```

---

## Validation avant production (gate manuel)

L'environnement GitHub **production** est configuré avec des *Required reviewers*.
Le job `deploy-production` se met en pause automatiquement et attend l'approbation
d'un **binôme ou du formateur** dans GitHub Actions avant de déployer.

Configuration : `Settings > Environments > production > Required reviewers`

---

## Registre des déploiements

| Version | Date | Auteur | Environnement | Commande | Résultat |
|---|---|---|---|---|---|
| v0.1.0 | 2026-06-11 | AMADOU | staging | `sh scripts/deploy-staging.sh` | ✅ succès |
