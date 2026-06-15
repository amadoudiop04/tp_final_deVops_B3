# RACI — ShopLite

## Définition

| Lettre | Signification | Rôle |
|--------|---------------|------|
| **R** | Responsible | Réalise concrètement l'action |
| **A** | Accountable | Porte la responsabilité finale, valide |
| **C** | Consulted | Consulté avant ou pendant l'action |
| **I** | Informed | Tenu informé du résultat |

---

## Équipe ShopLite

Dans ce TP, AMADOU couvre les rôles **DevOps / DBA / QA**.

| Rôle | Responsabilité |
|------|---------------|
| Product Owner (PO) | Impact métier, décision de rollback |
| Développeur API | Code backend, diagnostic route cassée |
| Développeur Frontend | Affichage catalogue, impact utilisateur |
| DevOps / Release Manager | CI/CD, Docker, tags, déploiement, rollback |
| DBA / Référent données | Backup PostgreSQL, intégrité des données |
| QA / Testeur | Exécution des tests, validation rouge/vert |
| Incident Manager | Communication, timeline, compte rendu |

---

## Matrice RACI

| Activité | PO | API | Frontend | DevOps | DBA | QA | Inc. Manager |
|----------|----|----|----------|--------|-----|----|-------------|
| Créer la version stable Git | I | C | C | **R/A** | I | C | I |
| Mettre en place Docker Compose | I | C | C | **R/A** | C | I | I |
| Configurer la CI/CD | I | C | C | **R/A** | I | C | I |
| Ajouter le test /api/products | C | R | I | C | I | **R/A** | I |
| Sauvegarder PostgreSQL | I | I | I | C | **R/A** | I | I |
| Provoquer l'incident contrôlé | **A** | C | C | **R** | C | C | I |
| Diagnostiquer l'incident | C | **R** | C | **R/A** | C | C | I |
| Décider le rollback | **A** | C | C | R | C | C | I |
| Exécuter le rollback | I | I | I | **R/A** | C | I | I |
| Vérifier les données après rollback | I | I | I | C | **R/A** | C | I |
| Valider les tests après rollback | **A** | C | I | C | I | **R** | I |
| Rédiger le rapport d'incident | I | C | I | C | I | C | **R/A** |

---

## Timeline incident contrôlé — ShopLite v1.1.0

| Heure | Action | Responsable | Résultat |
|-------|--------|------------|---------|
| 10:00 | Déploiement v1.1.0 en staging | DevOps | Stack démarrée |
| 10:02 | Smoke test post-déploiement | QA | PASS |
| 10:05 | Incident simulé : `DROP TABLE products` | DevOps | Table supprimée |
| 10:06 | Détection erreur `/api/products` | QA | Test rouge — HTTP 500 |
| 10:07 | Analyse logs API (`scripts/diagnose.sh`) | DevOps | Erreur `relation "products" does not exist` |
| 10:09 | Vérification intégrité données PostgreSQL | DBA | Volume `shoplite_pgdata` intact |
| 10:10 | Décision rollback validée | PO | Rollback vers v1.0.3 autorisé |
| 10:11 | Backup PostgreSQL avant correction | DBA | `backups/shoplite_2026-06-15_10-11-00.sql.gz` créé |
| 10:12 | Exécution rollback (`scripts/rollback.sh v1.0.3`) | DevOps | Stack relancée, health check OK |
| 10:14 | Smoke test post-rollback | QA | PASS — `source: database`, 5 produits |
| 10:15 | Données PostgreSQL vérifiées | DBA | 5 produits présents, aucune perte |
| 10:16 | Rapport d'incident généré | DevOps | `docs/incidents/incident_2026-06-15_10-12-00.md` |
| 10:18 | Communication équipe | Incident Manager | Incident clos — service restauré |

---

## Incident report — CI-001 (ESLint v9)

Voir [docs/INCIDENT.md](INCIDENT.md) pour le rapport complet de l'incident ESLint v9 flat config survenu en CI.

**Résumé :**
- **Impact :** CI bloquée sur tous les pushes
- **Cause :** ESLint v9 ne reconnaît plus `.eslintrc`, attend `eslint.config.js`
- **Résolution :** Création de `api/eslint.config.js` avec flat config
- **Durée :** ~20 minutes
- **Prévention :** Tester `npm run lint` en local avant le premier push
