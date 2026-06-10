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

## Orchestration locale avec Docker Compose

### Démarrage complet — `docker compose up -d --build`

Cette commande construit les images et démarre tous les services en arrière-plan. On remarque que `shoplite_db` passe en `Healthy` avant que l'API ne démarre : c'est le `depends_on: condition: service_healthy` qui force cette attente, évitant que l'API tente de se connecter à une base pas encore prête. Les layers déjà construits sont réutilisés depuis le cache Docker, ce qui accélère les reconstructions suivantes.

![docker compose up -d --build](img/dc-settings1.png)

---

### État des services — `docker compose ps`

```
NAME               SERVICE   STATUS                   PORTS
shoplite_db        db        Up (healthy)             5432/tcp
shoplite_api       api       Up (health: starting)    3000/tcp
shoplite_frontend  frontend  Up (health: starting)    80/tcp
shoplite_proxy     proxy     Up                       0.0.0.0:8080->80/tcp
```

`db` est le seul service déjà `healthy` car son healthcheck (`pg_isready`) est plus rapide. Le `proxy` est le seul exposé sur l'hôte (port `8080`) — les autres services communiquent uniquement via le réseau interne `shoplite_net`.

---

### Logs de l'API — `docker compose logs --tail=80 api`

```json
{"level":"info","message":"ShopLite API started","port":3000,"timestamp":"2026-06-10T12:23:39.005Z"}
{"level":"info","method":"GET","path":"/health","status":200,"duration_ms":26,"timestamp":"2026-06-10T12:23:43.870Z"}
```

Les logs sont en JSON structuré, ce qui facilite leur exploitation dans un outil de monitoring. Le second log montre le healthcheck Docker qui interroge `/health` — preuve que la rotation `json-file` avec `max-size: 10m` est bien active.

---

### Redémarrage ciblé — `docker compose restart api`

```bash
docker compose restart api
# → Container shoplite_api Restarting → Started
```

Seul le conteneur `api` est redémarré, `db`, `frontend` et `proxy` continuent de tourner sans interruption. C'est utile pour appliquer un changement de variable d'environnement sans reconstruire l'image ni couper l'accès au frontend.

---

### Rebuild ciblé — `docker compose up -d --build api`

Contrairement à `restart`, cette commande reconstruit l'image avant de recréer le conteneur. Docker réévalue le `depends_on: service_healthy` même pour un rebuild ciblé, donc l'API attend à nouveau que `db` soit prête avant de démarrer.

![docker compose up -d --build api](img/dc-settings2.png)

---

### Configuration fusionnée staging — `docker compose config`

```bash
docker compose -f docker-compose.yml -f docker-compose.staging.yml config
```

Cette commande affiche la configuration finale après fusion des deux fichiers, avec toutes les variables du `.env` interpolées. On peut vérifier que l'override staging a bien appliqué `APP_VERSION: staging-starter` sur l'API et ajouté le port `8081` sur le proxy — sans toucher aux autres services.

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
