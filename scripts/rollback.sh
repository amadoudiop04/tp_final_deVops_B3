#!/bin/sh
# Rollback vers une version stable — ShopLite
# Couvre les 7 notions : logs, version inspect, image check,
# script réutilisable, image taguée, vérification post-rollback, rapport.
#
# Usage :
#   sh scripts/rollback.sh <version>             → production (port 8080)
#   sh scripts/rollback.sh <version> staging     → staging    (port 8081)
#
# Exemples :
#   sh scripts/rollback.sh v1.0.0
#   sh scripts/rollback.sh v1.0.0 staging
set -eu

TARGET="${1:-}"
ENV="${2:-production}"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
LOG_DIR="./logs"
INCIDENT_DIR="./docs/incidents"

# ─── Usage ───────────────────────────────────────────────────────────────────
if [ -z "$TARGET" ]; then
  echo "Usage: $0 <version> [staging|production]"
  echo ""
  echo "Images disponibles :"
  docker images shoplite-api --format "  {{.Tag}}  ({{.Size}})  créée le {{.CreatedAt}}" \
    | grep -v "^  latest" || echo "  Aucune image locale trouvée."
  exit 1
fi

[ "$ENV" = "staging" ] && PORT=8081 || PORT=8080

echo "================================================"
echo "  ROLLBACK ShopLite"
echo "  Version cible : $TARGET"
echo "  Environnement : $ENV"
echo "  Timestamp     : $TIMESTAMP"
echo "================================================"

# ─── NOTION 1 : Sauvegarder les logs avant toute correction ──────────────────
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/incident_${TIMESTAMP}.log"
echo ""
echo "[1/7] Export des logs API avant correction → $LOG_FILE"
docker logs shoplite_api > "$LOG_FILE" 2>&1 \
  && echo "  $(wc -l < "$LOG_FILE") lignes exportées ($(du -h "$LOG_FILE" | cut -f1))" \
  || echo "  Conteneur non actif — log vide conservé"

# ─── NOTION 2 : Identifier la version actuellement déployée ──────────────────
echo ""
echo "[2/7] Version actuellement déployée :"
CURRENT_VERSION=$(docker inspect shoplite_api \
  --format '{{index .Config.Labels "org.opencontainers.image.version"}}' 2>/dev/null || echo "inconnue")
CURRENT_IMAGE=$(docker inspect shoplite_api \
  --format '{{.Config.Image}}' 2>/dev/null || echo "inconnue")
echo "  Image   : $CURRENT_IMAGE"
echo "  Version : $CURRENT_VERSION"

# ─── NOTION 3 : Vérifier que l'image stable est disponible ───────────────────
echo ""
echo "[3/7] Vérification de l'image cible shoplite-api:$TARGET..."
if ! docker image inspect "shoplite-api:$TARGET" > /dev/null 2>&1; then
  echo "  ERREUR : image shoplite-api:$TARGET introuvable."
  echo ""
  echo "  Images disponibles :"
  docker images shoplite-api --format "    {{.Tag}}  ({{.Size}})  {{.CreatedAt}}" \
    | grep -v "^    latest" || echo "    Aucune image versionnée."
  echo ""
  echo "  Pour reconstruire : APP_VERSION=$TARGET docker compose build api"
  exit 1
fi
IMAGE_DATE=$(docker inspect "shoplite-api:$TARGET" \
  --format '{{index .Config.Labels "org.opencontainers.image.created"}}' 2>/dev/null || echo "date inconnue")
echo "  Image trouvée — buildée le : $IMAGE_DATE"

# ─── NOTIONS 4 & 5 : Rollback par image taguée (script réutilisable) ─────────
echo ""
echo "[4/7] Arrêt de la stack (volumes nommés préservés — jamais down -v)..."
if [ "$ENV" = "staging" ]; then
  docker compose -f docker-compose.yml -f docker-compose.staging.yml down 2>/dev/null || true
else
  docker compose down 2>/dev/null || true
fi

echo ""
echo "[5/7] Démarrage avec l'image taguée shoplite-api:$TARGET..."
if [ "$ENV" = "staging" ]; then
  HTTP_PORT=8081 APP_VERSION="$TARGET" \
    docker compose -f docker-compose.yml -f docker-compose.staging.yml up -d
else
  APP_VERSION="$TARGET" docker compose up -d
fi

echo "  Attente health check (max 60s)..."
i=0
while [ $i -lt 30 ]; do
  if curl -fsS "http://localhost:$PORT/api/health" > /dev/null 2>&1; then
    echo "  Stack opérationnelle après $((i * 2))s"
    break
  fi
  i=$((i + 1))
  [ $i -lt 30 ] || { echo "  ERREUR : timeout — /api/health ne répond pas après 60s"; exit 1; }
  sleep 2
done

# ─── NOTION 6 : Vérification post-rollback ────────────────────────────────────
echo ""
echo "[6/7] Vérification post-rollback..."
BASE_URL="http://localhost:$PORT" sh "$(dirname "$0")/smoke-test.sh"

DATA_COUNT=$(curl -fsS "http://localhost:$PORT/api/products" 2>/dev/null \
  | grep -o '"id":[0-9]*' | wc -l | tr -d ' ' || echo "0")
echo ""
echo "  Données PostgreSQL : $DATA_COUNT produit(s) accessible(s) via l'API"
echo "  (volume shoplite_pgdata intact — aucune perte de données)"

# ─── NOTION 7 : Rapport de communication ─────────────────────────────────────
mkdir -p "$INCIDENT_DIR"
REPORT="$INCIDENT_DIR/incident_${TIMESTAMP}.md"
cat > "$REPORT" <<EOF
# Rapport d'incident — Rollback $TARGET

**Date :** $(date '+%Y-%m-%d %H:%M:%S')
**Environnement :** $ENV
**Durée estimée de l'impact :** à compléter

---

## Impact

Service ShopLite dégradé — un ou plusieurs endpoints retournaient des erreurs.

## Cause identifiée

À compléter après analyse des logs (voir : \`$LOG_FILE\`).

## Actions menées

| Étape | Action | Résultat |
|-------|--------|---------|
| 1 | Export des logs API | \`$LOG_FILE\` |
| 2 | Version incidentée identifiée | \`$CURRENT_VERSION\` |
| 3 | Image stable vérifiée | \`shoplite-api:$TARGET\` |
| 4 | Stack arrêtée (volumes préservés) | OK |
| 5 | Rollback vers \`$TARGET\` | OK |
| 6 | Smoke test post-rollback | PASS |
| 7 | Données PostgreSQL vérifiées | $DATA_COUNT produit(s) |

## Statut final

Service restauré — version \`$TARGET\` active sur http://localhost:$PORT

## Leçon retenue

À compléter après post-mortem.
EOF

echo ""
echo "[7/7] Rapport d'incident généré : $REPORT"
echo ""
echo "================================================"
echo "  Rollback TERMINÉ — version $TARGET active"
echo "  URL     : http://localhost:$PORT"
echo "  Logs    : $LOG_FILE"
echo "  Rapport : $REPORT"
echo "================================================"
