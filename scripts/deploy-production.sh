#!/bin/sh
# Deploiement local PRODUCTION - ShopLite (port 8080)
# Usage : sh scripts/deploy-production.sh <version>
# Exemple: sh scripts/deploy-production.sh v1.0.0
set -eu

TARGET="${1:-}"
[ -n "$TARGET" ] || { echo "Usage: $0 <version>  ex: $0 v1.0.0"; exit 1; }

GIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
AUTHOR=$(git config user.name 2>/dev/null || echo "unknown")

echo "=== Deploy PRODUCTION | version=$TARGET | auteur=$AUTHOR ==="
printf "Continuer en production ? [y/N] "
read -r answer
[ "$answer" = "y" ] || { echo "Annule."; exit 0; }

APP_VERSION="$TARGET" GIT_SHA="$GIT_SHA" BUILD_DATE="$BUILD_DATE" \
  docker compose up -d --build

echo "Attente disponibilite..."
i=0
while [ $i -lt 30 ]; do
  curl -fsS http://localhost:8080/api/health > /dev/null 2>&1 && break
  i=$((i + 1))
  [ $i -lt 30 ] || { echo "ERREUR: timeout health check"; exit 1; }
  sleep 2
done

BASE_URL=http://localhost:8080 sh "$(dirname "$0")/smoke-test.sh"
echo "Production disponible : http://localhost:8080"
