# Architecture du projet

## 1. Protection de la branche `main`

La branche `main` est protégée sur GitHub. Il est impossible de pousser directement dessus.  
Toute modification doit passer par une **Pull Request**.

**Règles configurées :**
- 1 approbation obligatoire avant de merger
- Le CI doit être vert (tests passants)
- La branche doit être à jour avec `main`

![Branch protection](img/image.png)

---

## 2. Template de Pull Request

Le fichier `.github/pull_request_template.md` est automatiquement chargé quand on ouvre une PR sur GitHub.  
Il oblige l'auteur à remplir un formulaire structuré avant de demander une review.

**Le template contient :**
- Le type de changement (bug fix, nouvelle fonctionnalité, refactoring)
- L'objectif de la PR en quelques lignes
- Une checklist de vérifications à cocher
- Les risques éventuels et comment annuler si besoin

Tant que la checklist n'est pas complète et qu'il n'y a pas d'approbation, le merge est bloqué.

![Pull request avec template](img/pull_request.png)

---

## 3. Merge d'une Pull Request

Une fois la PR approuvée et le CI vert, le merge est autorisé.  
GitHub fusionne la branche dans `main` et propose de supprimer la branche source.

![Merge réussi](img/merge.png)

---

## Flux de travail résumé
