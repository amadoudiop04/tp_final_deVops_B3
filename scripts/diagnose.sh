#!/bin/sh
# Diagnostic de l'état courant — ShopLite
# Identifie la version déployée, exporte les logs et lance un smoke test.
#
# Usage :
#   sh scripts/diagnose.sh             → production (port 8080)
#   sh scripts/diagnose.sh staging     → staging    (port 8081)
set -eu

ENV="${1:-production}"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
LOG_DIR="./logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/diagnose_${TIMESTAMP}.log"

[ "$ENV" = "staging" ] && PORT=8081 || PORT=8080

echo "================================================"
echo "  Diagnostic ShopLite — $ENV (port $PORT)"
echo "  Timestamp : $TIMESTAMP"
echo "================================================"

# ─── Version déployée via docker inspect ─────────────────────────────────────
echo ""
echo "[1] Version déployée (docker inspect labels) :"
docker inspect shoplite_api --format \
  '  Image   : {{.Config.Image}}
  Version : {{index .Config.Labels "org.opencontainers.image.version"}}
  SHA     : {{index .Config.Labels "org.opencontainers.image.revision"}}
  Build   : {{index .Config.Labels "org.opencontainers.image.created"}}' \
  2>/dev/null || echo "  Conteneur shoplite_api non trouvé — stack non démarrée ?"

# ─── Images versionnées disponibles ──────────────────────────────────────────
echo ""
echo "[2] Images shoplite-api disponibles localement :"
docker images shoplite-api --format "  {{.Tag}}  ({{.Size}})  {{.CreatedAt}}" \
  | grep -v "^  latest" || echo "  Aucune image versionnée trouvée."

# ─── État des conteneurs ─────────────────────────────────────────────────────
echo ""
echo "[3] État des conteneurs :"
docker compose ps 2>/dev/null || echo "  Stack non démarrée."

# ─── Derniers logs API ───────────────────────────────────────────────────────
echo ""
echo "[4] Dernières 20 lignes de logs API :"
docker logs --tail 20 shoplite_api 2>&1 || echo "  Conteneur API non disponible."

echo ""
echo "  Export complet → $LOG_FILE"
docker logs shoplite_api > "$LOG_FILE" 2>&1 || true

# ─── Derniers commits Git ────────────────────────────────────────────────────
echo ""
echo "[5] Derniers commits Git :"
git log --oneline -5 2>/dev/null || echo "  Pas de dépôt Git trouvé."

# ─── Smoke test ──────────────────────────────────────────────────────────────
echo ""
echo "[6] Smoke test :"
BASE_URL="http://localhost:$PORT" sh "$(dirname "$0")/smoke-test.sh" || true

echo ""
echo "================================================"
echo "  Diagnostic terminé"
echo "  Log complet : $LOG_FILE"
echo "================================================"
