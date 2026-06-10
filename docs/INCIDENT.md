# Incidents

## CI-001 — Échec du job `lint` sur les premiers runs CI

**Date :** 2026-06-10
**Sévérité :** Moyenne — la CI bloquait tous les pushes sur la branche `feat/dc-automatisation`

### Constat

Les deux premiers runs CI ont échoué en 22 secondes. Le job `lint` s'arrêtait immédiatement avec l'erreur suivante :

```
ESLint couldn't find an eslint.config.(js|mjs|cjs) file.
```

![Workflow en échec](img/workflow%20error.png)

### Cause

ESLint v9 (installé dans `api/package.json`) a abandonné le format `.eslintrc.*` au profit du nouveau format `eslint.config.js`. Le projet ne contenait aucun fichier de configuration ESLint, ce qui rendait la commande `npm run lint` inutilisable.

De plus, les globaux Jest (`test`, `expect`) n'étaient pas déclarés, ce qui aurait provoqué des erreurs `no-undef` sur les fichiers de tests.

### Résolution

Création du fichier `api/eslint.config.js` avec deux blocs de configuration : un pour les fichiers source (`src/`) et un pour les tests (`tests/`) incluant les globaux Jest.

![Workflow résolu](img/workflow-succes.png)

### Leçon

Vérifier la compatibilité des outils (ESLint v9 = flat config obligatoire) avant de les intégrer dans la CI. Tester `npm run lint` localement avant le premier push.
