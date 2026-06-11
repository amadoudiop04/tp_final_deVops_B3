# Modifications apportées — ShopLite

---

## Partie 1 — Tests & Qualité

| Élément | Fichier | Ce qui a été fait |
|---------|---------|------------------|
| Tests unitaires | `api/tests/products.unit.test.js` | Tests des routes `/products` avec mock Jest (pas de vraie DB) |
| Tests d'intégration | `api/tests/products.integration.test.js` | Tests sur vraie PostgreSQL + cycle incident (DROP TABLE) → rollback (init.sql) |
| Tests d'erreurs | `api/tests/errors.test.js` | Vérification des cas 404, 400 (limit invalide), 500 (DB down) |
| Tests health | `api/tests/health.test.js` | Tests `/health` (DB ok → 200, DB down → 503) et `/ready` |
| ESLint | `api/eslint.config.js` | Règles de qualité : `no-var`, `prefer-const`, `eqeqeq`, `no-unused-vars` |
| Prettier | `api/.prettierrc` | Formatage uniforme avec `endOfLine: "lf"` pour compatibilité Windows/Linux |
| Coverage | `api/package.json` | Seuil Jest à 80% (lines, functions, branches, statements) |
| CI | `.github/workflows/ci.yml` | 5 jobs : lint, tests unitaires, tests intégration, audit npm, scan Trivy |

---

## Partie 2 — Déploiement

| Élément | Fichier | Ce qui a été fait |
|---------|---------|------------------|
| Staging auto | `.github/workflows/cd.yml` | Push sur `Dev` → déploiement automatique sur port 8081 |
| Production sur tag | `.github/workflows/cd.yml` | Push d'un tag `v*` → déploiement production avec approbation manuelle |
| Override staging | `docker-compose.staging.yml` | `LOG_LEVEL=debug`, version `staging` — sans section `ports` (géré par `HTTP_PORT`) |
| Smoke test | `scripts/smoke-test.sh` | Vérifie `/ready`, `/health`, `/products` après chaque déploiement |
| Rollback | `scripts/rollback.sh` | Revenir à une version stable sans `docker compose down -v` |
| Deploy scripts | `scripts/deploy-staging.sh` / `deploy-production.sh` | Commandes locales pour déployer manuellement |
| Journal | `docs/DEPLOYMENTS.md` | Registre des déploiements et procédures de retour arrière |

---

## Partie 3 — Backup & Reprise

| Élément | Fichier | Ce qui a été fait |
|---------|---------|------------------|
| Backup pg_dump | `scripts/backup.sh` | `pg_dump` via `docker exec`, fichier compressé `shoplite_YYYY-MM-DD_HH-MM-SS.sql.gz` |
| Rétention | `scripts/backup.sh` | Suppression automatique des anciens fichiers, garde les 7 derniers |
| Restauration test | `scripts/restore-test.sh` | Restaure dans une base temporaire, vérifie les données, puis supprime la base |
| Volume hors container | `docker-compose.yml` | Bind mount `./backups:/backups` — les dumps survivent à tout arrêt Docker |
| Dossier backups | `backups/.gitkeep` | Dossier suivi par git, fichiers `.sql.gz` ignorés via `.gitignore` |

---

## Partie 4 — Rollback

| Élément | Fichier | Ce qui a été fait |
|---------|---------|------------------|
| Logs avant correction | `scripts/rollback.sh` | Export `docker logs shoplite_api` dans `logs/incident_TIMESTAMP.log` |
| Identifier version | `scripts/rollback.sh` / `scripts/diagnose.sh` | `docker inspect` sur les labels `org.opencontainers.image.version` |
| Vérifier image stable | `scripts/rollback.sh` | `docker image inspect shoplite-api:<version>` avant tout redémarrage |
| Script réutilisable | `scripts/rollback.sh` | Prend `<version>` et `[staging\|production]` en paramètres |
| Rollback par image taguée | `scripts/rollback.sh` | `APP_VERSION=$TARGET docker compose up -d` — image versionnée uniquement |
| Vérification post-rollback | `scripts/rollback.sh` | Smoke test complet + count des produits via l'API |
| Communication incident | `scripts/rollback.sh` | Génère `docs/incidents/incident_TIMESTAMP.md` avec tableau des actions |
| Scénario complet | `scripts/incident-scenario.sh` | Rejoue les 9 étapes : backup → incident → diagnostic → rollback → vérification |
| Diagnostic rapide | `scripts/diagnose.sh` | Affiche version, images dispo, logs, commits git, smoke test |

---

## Contrainte respectée dans toutes les parties

`docker compose down -v` n'est jamais utilisé — cette commande détruirait le volume `shoplite_pgdata` et toutes les données PostgreSQL avec lui.
