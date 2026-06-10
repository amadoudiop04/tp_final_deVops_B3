# Architecture du projet — ShopLite

## 1. Protection de la branche `main`

La branche `main` est protégée sur GitHub. On ne peut pas y pousser directement : toute modification passe obligatoirement par une Pull Request.

Pour qu'une PR puisse être mergée, il faut :
- Au moins une approbation d'un autre membre
- Que tous les tests CI soient passants
- Que la branche soit à jour avec `main`

![Branch protection](img/image.png)

---

## 2. Template de Pull Request

Quand on ouvre une PR, un formulaire se remplit automatiquement. Il demande de décrire ce que fait la PR, de cocher une checklist de vérifications et d'indiquer comment annuler si quelque chose se passe mal.

Ça évite les PR ouvertes à la va-vite sans contexte.

![Pull request avec template](img/pull_request.png)

---

## 3. Merge d'une Pull Request

Une fois la PR approuvée et les tests verts, le merge est autorisé. GitHub fusionne la branche dans `main` et propose de supprimer la branche source.

![Merge réussi](img/merge.png)

---

## 4. Pipeline CI — Tests et qualité

Le workflow `ci.yml` se déclenche à chaque push et à chaque PR. Il fait tourner plusieurs vérifications en parallèle :

- **Lint** : vérifie que le code respecte les règles ESLint et Prettier
- **Tests unitaires** : Jest avec une couverture minimum de 80%
- **Tests d'intégration** : sur une vraie base PostgreSQL, avec un cycle incident/rollback simulé
- **Audit de sécurité** : `npm audit` pour détecter les dépendances vulnérables

Si une étape échoue, le merge est bloqué.

![Historique des workflow runs](img/WOrkflow8.png)

---

## 5. Pipeline CD — Déploiement et tags Docker

Le workflow `cd.yml` se déclenche uniquement quand on pousse un tag Git de type `v1.0.0`. Il enchaîne trois étapes :

**Étape 1 — Build des images**
Les images Docker sont construites avec deux tags chacune : `:latest` et `:v1.0.0`. La version vient directement du tag Git, ce qui crée un lien traçable entre le code et l'image déployée.

**Étape 2 — Staging**
Les images sont déployées en staging. Un smoke test vérifie que tout démarre correctement.

**Étape 3 — Production**
Le déploiement en production n'est possible que si le tag Git commence par `v`. C'est une sécurité pour éviter tout déploiement accidentel.

```
build-images → deploy-staging → deploy-production
```
