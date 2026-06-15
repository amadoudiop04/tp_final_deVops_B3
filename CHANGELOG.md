# Changelog

Toutes les modifications notables de ce projet sont documentées ici.
Format basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/), versionnage [SemVer](https://semver.org/lang/fr/).

---

## [1.1.0] — 2026-06-15

### Ajouté
- Backup PostgreSQL automatisé avec `scripts/backup.sh` (pg_dump horodaté, rétention 7 jours)
- Script de restauration de test `scripts/restore-test.sh` (base temporaire isolée)
- Bind mount `./backups:/backups` dans docker-compose.yml pour stocker les dumps hors container
- Script de rollback complet `scripts/rollback.sh` (7 notions : logs, inspect, vérification image, rapport)
- Script de diagnostic `scripts/diagnose.sh`
- Scénario d'incident automatisé `scripts/incident-scenario.sh` (9 étapes)
- Documentation `docs/ROLLBACK.md`, `docs/BACKUP.md`, `docs/RACI.md`
- Matrix builds Node.js 18 et 20 dans la CI

### Modifié
- `scripts/rollback.sh` enrichi : export logs avant rollback, rapport incident généré automatiquement
- `.github/workflows/cd.yml` : injection des secrets GitHub pour les variables sensibles
- `.github/workflows/ci.yml` : ajout matrix Node 18/20

---

## [1.0.3] — 2026-06-12

### Ajouté
- `scripts/compare-versions.sh` et `scripts/compare-images.sh`
- `scripts/deploy-staging.sh` et `scripts/deploy-production.sh`
- `docs/DEPLOYMENTS.md` — journal de déploiement
- `docs/SECURITY.md` — checklist sécurité DevSecOps

### Modifié
- CI : ajout du job Trivy scan (image Docker + secrets dans le code)
- CI : ajout du job audit npm (`npm audit --audit-level=high` + `npm outdated`)

---

## [1.0.2] — 2026-06-11

### Ajouté
- Tests d'intégration avec vraie DB PostgreSQL (`api/tests/products.integration.test.js`)
- Tests de scénarios d'erreur 404/400/500 (`api/tests/errors.test.js`)
- Cycle incident/rollback automatisé dans la CI (DROP TABLE → init.sql)
- `api/eslint.config.js` — configuration ESLint v9 flat config
- `api/.prettierrc` — formatage uniforme avec `endOfLine: "lf"`

### Modifié
- `api/package.json` : seuil coverage Jest à 80%, scripts lint:ci et format:check
- `api/src/routes/products.js` : validation paramètre `?limit=` (400 si invalide)
- `api/src/routes/health.js` : réponse 503 si DB indisponible
- `api/src/app.js` : `/ready` vérifie la connexion PostgreSQL

---

## [1.0.1] — 2026-06-10

### Ajouté
- Workflow CD (`cd.yml`) : déploiement staging auto sur `Dev`, production sur tag `v*`
- `docker-compose.staging.yml` — override staging
- `scripts/smoke-test.sh` — vérification post-déploiement (5 checks)
- GitHub Environments `staging` et `prod` avec validation manuelle
- `docs/ARCHITECTURE.md` — diagrammes et screenshots

### Corrigé
- Migration vers ESLint v9 flat config (résolution incident CI-001)
- Port PostgreSQL `5433:5432` pour éviter conflit avec PostgreSQL local

---

## [1.0.0] — 2026-06-09

### Ajouté
- Dockerfiles API (`node:20-alpine`, multi-stage, non-root) et frontend (`nginx:1.27-alpine`)
- `docker-compose.yml` : services api, frontend, db, proxy avec healthchecks et resource limits
- `.env.example` documenté avec toutes les variables
- Labels OCI (`org.opencontainers.image.*`) dans les Dockerfiles
- Workflow CI (`ci.yml`) : lint, tests unitaires, tests d'intégration, audit, Trivy
- Protection de la branche `main` (PR obligatoire, CI verte, review)
- `.github/pull_request_template.md`
- `api/tests/products.unit.test.js` — tests unitaires avec mock Jest
- `api/src/middleware/logger.js` — logs JSON avec `request_id`
- `docs/INCIDENT.md` — rapport incident CI-001 (ESLint v9)
- `docs/DORA.md` — fiche DORA 4 indicateurs

---

## [0.1.0] — 2026-06-08

### Ajouté
- Projet starter ShopLite (API Node.js/Express + PostgreSQL + frontend)
- Structure initiale : `api/`, `database/init.sql`, `frontend/`
