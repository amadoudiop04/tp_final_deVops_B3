#!/usr/bin/env bash
# Compare shoplite-api:latest et shoplite-api:<version> après un build local.
# Couvre : historique des images (docker images) + comparaison avant rollback.
# Usage : ./scripts/compare-images.sh [version]
#   ./scripts/compare-images.sh         -> utilise le dernier tag Git
#   ./scripts/compare-images.sh v1.0.0  -> compare avec une version spécifique
set -euo pipefail

VERSION=${1:-$(git describe --tags --abbrev=0 2>/dev/null || echo "dev")}

echo "======================================================"
echo " Historique des images ShopLite (docker images)"
echo "======================================================"
docker images | grep -E "shoplite|REPOSITORY" || echo "Aucune image shoplite trouvée — lancez d'abord ./scripts/build-and-tag.sh"

echo ""
echo "======================================================"
echo " Comparaison  :latest  vs  :${VERSION}"
echo "======================================================"

for SERVICE in shoplite-api shoplite-frontend; do
  echo ""
  echo "--- ${SERVICE}:latest ---"
  docker inspect "${SERVICE}:latest" \
    --format 'ID={{.Id}} | Version={{index .Config.Labels "org.opencontainers.image.version"}} | SHA={{index .Config.Labels "org.opencontainers.image.revision"}} | Created={{index .Config.Labels "org.opencontainers.image.created"}}' \
    2>/dev/null || echo "Image ${SERVICE}:latest introuvable"

  echo "--- ${SERVICE}:${VERSION} ---"
  docker inspect "${SERVICE}:${VERSION}" \
    --format 'ID={{.Id}} | Version={{index .Config.Labels "org.opencontainers.image.version"}} | SHA={{index .Config.Labels "org.opencontainers.image.revision"}} | Created={{index .Config.Labels "org.opencontainers.image.created"}}' \
    2>/dev/null || echo "Image ${SERVICE}:${VERSION} introuvable"
done

echo ""
echo "======================================================"
echo " Entrypoint & ports — shoplite-api:${VERSION}"
echo "======================================================"
docker inspect "shoplite-api:${VERSION}" \
  --format 'Cmd={{.Config.Cmd}} | Ports={{range $p, $_ := .Config.ExposedPorts}}{{$p}} {{end}}' \
  2>/dev/null || echo "Image shoplite-api:${VERSION} introuvable"
