# Indicateurs DORA

Étapes pour configurer les règles de protection
Accédez aux paramètres de votre dépôt :

Allez sur votre dépôt GitHub.

Cliquez sur l'onglet Settings (Paramètres) en haut.

Accédez aux règles de branche :

Dans le menu latéral gauche, cliquez sur Branches.

Sous la section Branch protection rules, cliquez sur le bouton Add branch protection rule.

Définissez la branche cible :

Dans Branch name pattern, saisir le nom de la branche main.

Activez les options de protection :

Cochez Require a pull request before merging : Cela empêche de pousser directement sur la branche.

Cochez Require approvals : Définissez le nombre de revues nécessaires (1).

Cochez Require status checks to pass before merging :

Cochez Require branches to be up to date before merging.

Recherchez et sélectionnez les contrôles (CI/CD) qui doivent obligatoirement être "verts" (build, lint, test).

Sauvegardez :

Puis on clique Clique sur Create (ou Save changes) tout en bas de la page.

![alt text](image.png)

A compléter pendant le TP.
