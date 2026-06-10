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

### 1. Démarrage complet — `docker compose up -d --build`

Construction et démarrage de tous les services en mode détaché.

```bash
docker compose up -d --build
```

**Résultat :**
```
Image tp_final_devops_b3-frontend Built
Image tp_final_devops_b3-api Built
Network tp_final_devops_b3_shoplite_net Created
Volume tp_final_devops_b3_shoplite_pgdata Created
Container shoplite_db Started
Container shoplite_frontend Started
Container shoplite_db Healthy        ← healthcheck PostgreSQL validé
Container shoplite_api Started       ← api démarre après que db soit healthy
Container shoplite_proxy Started
```

![docker compose up -d --build](img/dc-settings1.png)

Points notables :
- Le volume nommé `shoplite_pgdata` est créé automatiquement pour persister les données PostgreSQL
- L'API attend que `shoplite_db` soit en état `Healthy` grâce à `depends_on: condition: service_healthy`
- Le cache Docker est exploité : les layers non modifiés (`CACHED`) ne sont pas reconstruits

---

### 2. État des services — `docker compose ps`

```bash
docker compose ps
```

**Résultat :**
```
NAME                IMAGE                         SERVICE    STATUS                          PORTS
shoplite_api        tp_final_devops_b3-api        api        Up (health: starting)           3000/tcp
shoplite_db         postgres:16-alpine            db         Up (healthy)                    5432/tcp
shoplite_frontend   tp_final_devops_b3-frontend   frontend   Up (health: starting)           80/tcp
shoplite_proxy      nginx:1.27-alpine             proxy      Up                              0.0.0.0:8080->80/tcp
```

- `db` est `healthy` : le healthcheck `pg_isready` répond correctement
- `proxy` expose le port `8080` sur l'hôte et route les requêtes vers `api` et `frontend`
- `api` et `frontend` sont en `health: starting` car leur sonde démarre après le lancement

---

### 3. Logs de l'API — `docker compose logs --tail=80 api`

```bash
docker compose logs --tail=80 api
```

**Résultat :**
```json
{"level":"info","message":"ShopLite API started","port":3000,"timestamp":"2026-06-10T12:23:39.005Z"}
{"level":"info","method":"GET","path":"/health","status":200,"duration_ms":26,"timestamp":"2026-06-10T12:23:43.870Z"}
```

- Les logs sont au format JSON structuré avec niveau, message, port et timestamp
- Le healthcheck Docker interroge `/health` toutes les 30s — le premier hit est visible dans les logs
- Le logging driver `json-file` avec rotation (`max-size: 10m`, `max-file: 3`) est actif

---

### 4. Redémarrage ciblé — `docker compose restart api`

```bash
docker compose restart api
```

**Résultat :**
```
Container shoplite_api Restarting
Container shoplite_api Started
```

**Logs après redémarrage :**
```json
{"level":"info","message":"ShopLite API started","port":3000,"timestamp":"2026-06-10T12:23:47.414Z"}
```

- Seul le service `api` est redémarré, les autres services (`db`, `frontend`, `proxy`) ne sont pas interrompus
- Le redémarrage ciblé est utile pour appliquer un changement de configuration sans affecter l'ensemble de la stack

---

### 5. Rebuild ciblé — `docker compose up -d --build api`

```bash
docker compose up -d --build api
```

**Résultat :**
```
Image tp_final_devops_b3-api Built   ← rebuild de l'image api uniquement
Container shoplite_db Running        ← db non touché
Container shoplite_api Recreate
Container shoplite_db Waiting        ← healthcheck vérifié avant redémarrage api
Container shoplite_db Healthy
Container shoplite_api Started
```

![docker compose up -d --build api](img/dc-settings2.png)

- Seule l'image `api` est reconstruite, les autres images sont inchangées
- Toutes les couches sont `CACHED` (code source non modifié) : rebuild quasi-instantané
- La condition `service_healthy` sur `db` est réévaluée même pour un rebuild ciblé

---

### 6. Configuration fusionnée staging — `docker compose config`

```bash
docker compose -f docker-compose.yml -f docker-compose.staging.yml config
```

**Résultat (extrait clé) :**
```yaml
services:
  api:
    environment:
      APP_VERSION: staging-starter   # ← override staging appliqué
    deploy:
      resources:
        limits:
          cpus: 0.5
          memory: "268435456"        # 256M
    logging:
      driver: json-file
      options:
        max-size: 10m
        max-file: "3"
  proxy:
    ports:
      - published: "8080"            # port base
      - published: "8081"            # ← port staging ajouté par l'override
```

- La commande `config` fusionne les deux fichiers et affiche la configuration résolue finale
- L'override staging surcharge `APP_VERSION` (`staging-starter`) et expose le port `8081`
- Les variables d'environnement du `.env` sont interpolées dans la config finale

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
