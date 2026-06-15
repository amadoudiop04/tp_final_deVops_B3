#!/usr/bin/env bash
# Compare deux versions de ShopLite : fichiers modifiés + images Docker.
# Usage : ./scripts/compare-versions.sh <v_stable> <v_nouvelle>
#   ./scripts/compare-versions.sh v1.0.0 v1.1.0
set -euo pipefail

V_STABLE="${1:-}"
V_NEW="${2:-}"

if [ -z "$V_STABLE" ] || [ -z "$V_NEW" ]; then
  echo "Usage: $0 <version_stable> <version_nouvelle>"
  echo "  ex: $0 v1.0.0 v1.1.0"
  exit 1
fi

echo "======================================================"
echo " Comparaison  $V_STABLE  →  $V_NEW"
echo "======================================================"

echo ""
echo "--- Fichiers modifiés entre $V_STABLE et $V_NEW ---"
git diff --stat "$V_STABLE" "$V_NEW" 2>/dev/null \
  || echo "Tags introuvables en local — vérifier que les deux tags existent."

echo ""
echo "--- Commits ajoutés dans $V_NEW ---"
git log --oneline "$V_STABLE".."$V_NEW" 2>/dev/null \
  || echo "Impossible de comparer les commits."

echo ""
echo "--- Images Docker disponibles ---"
docker images | grep -E "shoplite|REPOSITORY" || echo "Aucune image shoplite trouvée."

echo ""
echo "--- Image $V_STABLE ---"
docker inspect "shoplite-api:$V_STABLE" \
  --format 'Version={{index .Config.Labels "org.opencontainers.image.version"}}  SHA={{index .Config.Labels "org.opencontainers.image.revision"}}  Taille={{.Size}}' \
  2>/dev/null || echo "Image shoplite-api:$V_STABLE introuvable en local."

echo ""
echo "--- Image $V_NEW ---"
docker inspect "shoplite-api:$V_NEW" \
  --format 'Version={{index .Config.Labels "org.opencontainers.image.version"}}  SHA={{index .Config.Labels "org.opencontainers.image.revision"}}  Taille={{.Size}}' \
  2>/dev/null || echo "Image shoplite-api:$V_NEW introuvable en local."
