# Indicateurs DORA

## Optimisation des Dockerfiles

### Dockerfile Backend (`api/Dockerfile`)

Le Dockerfile backend a été refactorisé avec un **build multi-stage** et plusieurs améliorations :

**Stage 1 — `deps` (installation des dépendances)**
- Utilisation de `node:20-alpine` comme image de base légère
- Copie uniquement des fichiers `package*.json` en premier pour **exploiter le cache Docker** : si les dépendances n'ont pas changé, cette couche n'est pas reconstruite
- `npm ci --omit=dev` : installation propre sans les dépendances de développement
- `npm cache clean --force` : suppression du cache npm pour réduire la taille de l'image

**Stage 2 — `runner` (image finale)**
- Image finale allégée : seul le résultat du stage `deps` est copié (`node_modules`), npm n'est pas présent dans l'image de production
- Variables d'environnement explicites : `NODE_ENV=production`, `API_PORT=3000`, `NODE_OPTIONS="--max-old-space-size=512"` pour éviter les crashs silencieux
- **Durcissement sécurité** : création d'un groupe système `nodejs` et d'un utilisateur non-root `appuser` (UID 1001), les fichiers applicatifs lui appartiennent
- Exécution sous `USER appuser` : le processus ne tourne pas en root
- `HEALTHCHECK` : sonde toutes les 30s via `wget` sur `/health`, 3 tentatives avant de considérer le conteneur unhealthy
- `CMD` en exec form avec `--enable-source-maps` pour des stack traces exploitables en production

---

### Dockerfile Frontend (`frontend/Dockerfile`)

Le Dockerfile frontend est basé sur **`nginx:1.27-alpine`** :

- Copie de la configuration Nginx personnalisée (`nginx.conf`) et des sources statiques
- `HEALTHCHECK` : sonde toutes les 30s via `wget` sur la racine `/`

**Configuration Nginx (`nginx.conf`) :**
- **Compression gzip** activée sur `text/plain`, `text/css`, `application/javascript`, `application/json` pour réduire la bande passante
- **En-têtes de sécurité** :
  - `X-Frame-Options: SAMEORIGIN` — protection contre le clickjacking
  - `X-Content-Type-Options: nosniff` — protection contre le MIME-sniffing
- **Cache statique** : les assets CSS, JS, images et favicon sont mis en cache 1 an avec `Cache-Control: public, immutable`
- **SPA routing** : `try_files $uri $uri/ /index.html` pour gérer le routage côté client

---

## Inspection de l'image Docker API

Commandes exécutées :

```bash
docker build -t shoplite-api:local ./api
docker images shoplite-api
docker inspect shoplite-api:local
```

Résultat :

![Inspection de l'image shoplite-api:local](img/dc-img-inspect.png)
