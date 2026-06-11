# Sécurité — ShopLite

## Checklist sécurité

| Point de contrôle | État |
|---|---|
| Aucun secret commité dans Git | ✅ `.env` dans `.gitignore` |
| `.env.example` sans vraie valeur sensible | ✅ Valeurs d'exemple uniquement |
| API ne tourne pas en root | ✅ Utilisateur `appuser` dans le Dockerfile |
| Ports exposés limités au nécessaire | ✅ Seul le proxy est exposé à l'extérieur |
| Dépendances sans vulnérabilité connue | ✅ `npm audit` → 0 vulnérabilité |
| Image Docker scannée en CI | ✅ Trivy sur chaque push |
| Logs sans données sensibles | ✅ Headers masqués avec `[MASKED]` |
| Healthcheck actif sur les conteneurs | ✅ `/ready` sur l'API, `pg_isready` sur la DB |

---

## Lecture du Dockerfile API

| Élément | Valeur |
|---|---|
| Image de base | `node:20-alpine` (légère, moins de surface d'attaque) |
| Port exposé | `3000` |
| Commande de démarrage | `node --enable-source-maps src/server.js` |
| Utilisateur | `appuser` (non-root, UID 1001) |
| Dépendances de dev | Absentes (installées avec `--omit=dev`) |

---

## Vérification des secrets

Le fichier `.env` contient les vrais mots de passe — il est dans `.gitignore` et n'est jamais commité.

```
.gitignore :
  .env
  .env.*
  !.env.example   ← seul ce fichier est tracké
```

Seul `.env.example` est commité, et il ne contient que des valeurs d'exemple comme `shoplite_password`.

Le scan Trivy (`scanners: secret`) vérifie à chaque push qu'aucun vrai secret n'est présent dans le code.

---

## Contrôle des ports exposés

| Service | Port interne | Port externe | Nécessaire |
|---|---|---|---|
| API | 3000 | ❌ non exposé | Le proxy fait le relais |
| Frontend | 80 | ❌ non exposé | Le proxy fait le relais |
| Proxy | 80 | ✅ 8080 (dev) / 8081 (staging) / 8082 (prod) | Seul point d'entrée |
| DB | 5432 | ✅ 5433 (dev) / 5434 (staging) / 5435 (prod) | Accès local uniquement |

Seuls le proxy et la DB sont accessibles depuis la machine hôte. L'API et le frontend ne sont joignables que depuis le réseau interne Docker.

---

## Vérification du fichier `.env.example`

Le fichier `.env.example` documente toutes les variables attendues par l'application. Comparaison avec les variables utilisées dans le code :

| Variable | Dans `.env.example` | Utilisée dans le code |
|---|---|---|
| `NODE_ENV` | ✅ | ✅ |
| `API_PORT` | ✅ | ✅ |
| `DATABASE_URL` | ✅ | ✅ |
| `APP_VERSION` | ✅ | ✅ |
| `LOG_LEVEL` | ✅ | ✅ |
| `POSTGRES_DB` / `POSTGRES_USER` / `POSTGRES_PASSWORD` | ✅ | ✅ (docker-compose) |

Aucune variable manquante.

---

## Dépendances obsolètes — `npm outdated`

Résultat obtenu le 2026-06-11 :

| Paquet | Version actuelle | Dernière version | Type de mise à jour |
|---|---|---|---|
| `prettier` | 3.8.3 | 3.8.4 | Patch |
| `dotenv` | 16.6.1 | 17.4.2 | Majeure |
| `eslint` | 9.39.4 | 10.4.1 | Majeure |
| `express` | 4.22.2 | 5.2.1 | Majeure |
| `jest` | 29.7.0 | 30.4.2 | Majeure |

---

## Classement des risques

| Risque | Niveau | Explication |
|---|---|---|
| `express` en version 4 (v5 disponible) | Moyen | Express 5 introduit des changements d'API — une mise à jour non testée peut casser les routes |
| `dotenv` version majeure disponible | Moyen | Changements de comportement possibles sur le chargement des variables |
| `eslint` / `jest` versions majeures | Faible | Outils de développement uniquement, n'affectent pas la production |
| `prettier` patch disponible | Faible | Mise à jour sûre, aucun risque fonctionnel |
| 0 vulnérabilité `npm audit` | ✅ Aucun | Aucune dépendance avec CVE connue |
| Image Docker (`node:20-alpine`) | Faible | Alpine minimise la surface d'attaque, Trivy vérifie en CI |
