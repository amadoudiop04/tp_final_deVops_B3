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

## Important

Le projet contient maintenant le minimum pour tourner avec Docker.
Les etudiants doivent l'ameliorer pendant le TP pour atteindre les exigences finales.
