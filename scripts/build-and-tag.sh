#!/usr/bin/env bash
# Build et tag les images Docker en liant le tag Git à la version Docker.
# Usage : ./scripts/build-and-tag.sh [version]
#   ./scripts/build-and-tag.sh          -> utilise le dernier tag Git (ex: v1.0.0)
#   ./scripts/build-and-tag.sh v2.0.0   -> force une version spécifique
set -euo pipefail

VERSION=${1:-$(git describe --tags --abbrev=0 2>/dev/null || echo "dev")}
GIT_SHA=$(git rev-parse --short HEAD)
BUILD_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)

echo "==> Build ShopLite  version=${VERSION}  sha=${GIT_SHA}  date=${BUILD_DATE}"

docker build \
  --build-arg BUILD_VERSION="${VERSION}" \
  --build-arg GIT_SHA="${GIT_SHA}" \
  --build-arg BUILD_DATE="${BUILD_DATE}" \
  -t shoplite-api:latest \
  -t shoplite-api:"${VERSION}" \
  ./api

docker build \
  --build-arg BUILD_VERSION="${VERSION}" \
  --build-arg GIT_SHA="${GIT_SHA}" \
  --build-arg BUILD_DATE="${BUILD_DATE}" \
  -t shoplite-frontend:latest \
  -t shoplite-frontend:"${VERSION}" \
  ./frontend

echo ""
echo "==> Images disponibles (docker images) :"
docker images | grep shoplite
