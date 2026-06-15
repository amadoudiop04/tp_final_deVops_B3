# ShopLite - Starter TP final DevOps

[![CI](https://github.com/amadoudiop04/tp_final_deVops_B3/actions/workflows/ci.yml/badge.svg)](https://github.com/amadoudiop04/tp_final_deVops_B3/actions/workflows/ci.yml)
[![CD](https://github.com/amadoudiop04/tp_final_deVops_B3/actions/workflows/cd.yml/badge.svg)](https://github.com/amadoudiop04/tp_final_deVops_B3/actions/workflows/cd.yml)

Membres du groupe
Amadou Diop
Hamed Kaffa
B3 Dev
ShopLite est un projet de base pour un TP final DevOps.

Les etudiants recoivent uniquement ce socle applicatif :

- API Node.js / Express
- Frontend HTML / CSS / JS
- Script SQL PostgreSQL
- Un test de sante minimal
- Une configuration Docker minimale pour lancer le projet

Le travail du TP consiste a construire progressivement :

- Git propre et strategie de branches
- Ameliorer les Dockerfile API et frontend
- Ameliorer docker-compose dev / staging / prod
- CI/CD GitHub Actions
- tests automatises
- logs propres
- securite container
- backup PostgreSQL
- rollback sans perte de donnees
- documentation professionnelle

## Lancement rapide avec Docker

```bash
docker compose up -d --build
```

Ouvrir :

```text
http://localhost:8080
```

Tester :

```bash
curl http://localhost:8080/api/health
curl http://localhost:8080/api/products
```

Arreter sans supprimer les donnees :

```bash
docker compose down
```

## Lancement hors Docker pour prise en main

```bash
cd api
npm install
npm test
npm start
```

API :

```text
http://localhost:3000/health
http://localhost:3000/products
```

Frontend :

Ouvrir `frontend/src/index.html` dans un navigateur ou le servir avec un serveur statique.

## Commandes de diagnostic

```bash
# État des conteneurs
docker compose ps

# Logs de l'API (100 dernières lignes)
docker compose logs --tail=100 api

# Vérifier la santé de l'API
curl http://localhost:8080/api/health

# Vérifier la readiness
curl http://localhost:8080/api/ready

# Inspecter le conteneur API
docker inspect shoplite_api
```

---

## Tableau de suivi des incidents

| Symptôme | Heure | Cause | Commande utilisée | Résultat |
|---|---|---|---|---|
| API renvoie 503 | 2026-06-10 12:00 | Table `products` supprimée (simulation incident) | `psql ... -f database/init.sql` | ✅ Table restaurée, API OK |
| CI bloquée sur lint | 2026-06-10 09:00 | Fichier `eslint.config.js` manquant (ESLint v9) | Création de `api/eslint.config.js` | ✅ CI verte |
| Workflow CD timeout | 2026-06-11 14:00 | Docker Hub injoignable depuis le runner GitHub | Re-run du job | ✅ Passé au second run |
