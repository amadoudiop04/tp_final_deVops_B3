#!/bin/sh
# Rollback vers une version stable — ShopLite
# Usage :
#   sh scripts/rollback.sh <version>              → rollback production (port 8080)
#   sh scripts/rollback.sh <version> staging      → rollback staging    (port 8081)
#
# Exemples :
#   sh scripts/rollback.sh v1.0.0
#   sh scripts/rollback.sh v1.0.0 staging
set -eu

TARGET="${1:-}"
ENV="${2:-production}"

if [ -z "$TARGET" ]; then
  echo "Usage: $0 <version> [staging|production]"
  echo ""
  echo "Images disponibles :"
  docker images shoplite-api --format "  {{.Tag}}  ({{.Size}})  créée le {{.CreatedAt}}" \
    | grep -v "^  latest" || echo "  Aucune image locale trouvée."
  exit 1
fi

echo "================================================"
echo "  ROLLBACK ShopLite"
echo "  Version cible : $TARGET"
echo "  Environnement : $ENV"
echo "================================================"

# Vérifier que l'image cible existe
if ! docker image inspect "shoplite-api:$TARGET" > /dev/null 2>&1; then
  echo "ERREUR : image shoplite-api:$TARGET introuvable localement."
  echo "Reconstruire d'abord : APP_VERSION=$TARGET docker compose build"
  exit 1
fi

echo "[1/4] Arrêt de la stack en cours..."
if [ "$ENV" = "staging" ]; then
  docker compose -f docker-compose.yml -f docker-compose.staging.yml down 2>/dev/null || true
else
  docker compose down 2>/dev/null || true
fi

echo "[2/4] Démarrage avec la version $TARGET..."
if [ "$ENV" = "staging" ]; then
  HTTP_PORT=8081 APP_VERSION="$TARGET" \
    docker compose -f docker-compose.yml -f docker-compose.staging.yml up -d
  PORT=8081
else
  APP_VERSION="$TARGET" docker compose up -d
  PORT=8080
fi

echo "[3/4] Attente de la disponibilité (max 60s)..."
i=0
while [ $i -lt 30 ]; do
  if curl -fsS "http://localhost:$PORT/api/health" > /dev/null 2>&1; then
    echo "  Stack opérationnelle après $((i * 2))s"
    break
  fi
  i=$((i + 1))
  if [ $i -eq 30 ]; then
    echo "ERREUR : timeout — /api/health ne répond pas"
    exit 1
  fi
  sleep 2
done

echo "[4/4] Vérification santé..."
BASE_URL="http://localhost:$PORT" sh "$(dirname "$0")/smoke-test.sh"

echo ""
echo "Rollback terminé — version $TARGET active sur http://localhost:$PORT"
