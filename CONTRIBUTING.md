# Guide de contribution — ShopLite

## Stratégie de branches

```
main          ← production stable, protégée (PR + CI verte obligatoires)
Dev           ← intégration, déploiement staging automatique
feat/*        ← nouvelles fonctionnalités (ex: feat/backup)
hotfix/*      ← corrections urgentes depuis main
```

### Règles

- Ne jamais pousser directement sur `main`
- Toute modification passe par une Pull Request
- La branche doit être à jour avec `main` avant le merge
- La CI doit être verte (lint + tests + coverage ≥ 80%)
- Au moins une review approuvée obligatoire

---

## Commits conventionnels

Format : `type(scope): message`

| Type | Usage |
|------|-------|
| `feat` | Nouvelle fonctionnalité |
| `fix` | Correction de bug |
| `docs` | Documentation uniquement |
| `ci` | Modification CI/CD |
| `test` | Ajout ou modification de tests |
| `chore` | Maintenance (deps, config) |
| `hotfix` | Correction urgente en production |


## Ouvrir une Pull Request

1. Créer une branche depuis `Dev` : `git checkout -b feat/ma-feature`
2. Commiter avec le format conventionnel
3. Pousser : `git push origin feat/ma-feature`
4. Ouvrir la PR vers `Dev` sur GitHub
5. Remplir le template de PR (objectif, tests, rollback)
6. Attendre la CI verte + une approbation

---

## Workflow hotfix

```bash
# Depuis main
git checkout main
git checkout -b hotfix/v1.0.x

# Corriger, commiter
git commit -m "hotfix: description de la correction"

# Merger vers main
git checkout main
git merge --no-ff hotfix/v1.0.x
git tag v1.0.x

# Propager vers Dev
git checkout Dev
git merge --no-ff hotfix/v1.0.x

# Supprimer la branche
git branch -d hotfix/v1.0.x
```

---

## Revenir en arrière (git revert)

En cas de commit problématique en production, utiliser `git revert` plutôt que `git reset` :

```bash
# Annuler un commit spécifique (conserve l'historique)
git revert <sha-du-commit> --no-edit

```

---

## Qualité du code

Avant tout commit, vérifier :

```bash
cd api
npm run format:check   # vérifier le formatage Prettier
npm run lint:ci       
npm test               # tests unitaires
npm run test:coverage  
```