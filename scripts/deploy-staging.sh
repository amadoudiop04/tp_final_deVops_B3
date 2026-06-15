#!/bin/sh
# Deploiement local STAGING - ShopLite (port 8081)
# Usage : sh scripts/deploy-staging.sh [version]
set -eu

APP_VERSION="${1:-${APP_VERSION:-staging}}"
GIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)

echo "=== Deploy STAGING | version=$APP_VERSION | sha=$GIT_SHA ==="

# HTTP_PORT=8081 ecrase ${HTTP_PORT:-8080} dans docker-compose.yml
# → proxy ecoute uniquement sur 8081, pas de conflit avec la prod (8080)
HTTP_PORT=8081 APP_VERSION="$APP_VERSION" GIT_SHA="$GIT_SHA" BUILD_DATE="$BUILD_DATE" \
  docker compose -f docker-compose.yml -f docker-compose.staging.yml up -d --build

echo "Attente disponibilite..."
i=0
while [ $i -lt 30 ]; do
  curl -fsS http://localhost:8081/api/health > /dev/null 2>&1 && break
  i=$((i + 1))
  [ $i -lt 30 ] || { echo "ERREUR: timeout health check"; exit 1; }
  sleep 2
done

BASE_URL=http://localhost:8081 sh "$(dirname "$0")/smoke-test.sh"
echo "Staging disponible : http://localhost:8081"
