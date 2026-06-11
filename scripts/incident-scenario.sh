#!/bin/sh
# Scénario complet d'incident contrôlé et rollback — ShopLite
#
# Étapes :
#   1. Vérifier que la CI est verte et qu'une version stable existe
#   2. Sauvegarder PostgreSQL
#   3. Identifier et taguer la version stable
#   4. Constater que /api/products fonctionne (test PASS)
#   5. Provoquer un incident contrôlé (DROP TABLE products)
#   6. Constater que le test échoue
#   7. Diagnostiquer (version, logs, git)
#   8. Rollback sans supprimer les volumes
#   9. Constater que le test repasse et que les données existent
#
# Usage :
#   sh scripts/incident-scenario.sh <version-stable>
#   sh scripts/incident-scenario.sh v1.0.0
set -eu

STABLE="${1:-}"
PORT=8080
BASE_URL="http://localhost:$PORT"

if [ -z "$STABLE" ]; then
  echo "Usage: $0 <version-stable>  (ex: v1.0.0)"
  echo ""
  echo "Images disponibles :"
  docker images shoplite-api --format "  {{.Tag}}" | grep -v "^  latest" || echo "  Aucune image versionnée."
  exit 1
fi

# Séparateur visuel
step() {
  echo ""
  echo "──────────────────────────────────────────────"
  echo "  ÉTAPE $1"
  echo "──────────────────────────────────────────────"
}

echo "================================================"
echo "  SCÉNARIO INCIDENT/ROLLBACK — ShopLite"
echo "  Version stable de référence : $STABLE"
echo "================================================"

# ─── ÉTAPE 1 : Vérifier que la stack tourne ──────────────────────────────────
step "1 — Vérifier l'état initial"

if ! curl -fsS "$BASE_URL/api/health" > /dev/null 2>&1; then
  echo "  La stack n'est pas démarrée. Lancement..."
  APP_VERSION="$STABLE" docker compose up -d
  echo "  Attente health check..."
  i=0
  while [ $i -lt 30 ]; do
    curl -fsS "$BASE_URL/api/health" > /dev/null 2>&1 && break
    i=$((i + 1)); sleep 2
  done
fi

echo "  Stack démarrée — version en cours :"
docker inspect shoplite_api \
  --format '  Image : {{.Config.Image}} | Version : {{index .Config.Labels "org.opencontainers.image.version"}}' \
  2>/dev/null || echo "  (labels non disponibles)"

# ─── ÉTAPE 2 : Backup PostgreSQL ─────────────────────────────────────────────
step "2 — Sauvegarde PostgreSQL avant incident"

sh "$(dirname "$0")/backup.sh"

# ─── ÉTAPE 3 : Identifier la version stable ──────────────────────────────────
step "3 — Version stable de référence"

if docker image inspect "shoplite-api:$STABLE" > /dev/null 2>&1; then
  echo "  Image shoplite-api:$STABLE — disponible localement"
  docker images "shoplite-api" --format "  Tag={{.Tag}}  Size={{.Size}}  Created={{.CreatedAt}}" \
    | grep "$STABLE" || true
else
  echo "  ERREUR : image shoplite-api:$STABLE introuvable."
  echo "  Construire d'abord : APP_VERSION=$STABLE docker compose build api"
  exit 1
fi

# ─── ÉTAPE 4 : Vérifier que /api/products fonctionne (AVANT incident) ────────
step "4 — Test /api/products AVANT incident [attendu PASS]"

RESPONSE=$(curl -fsS "$BASE_URL/api/products" 2>/dev/null) || {
  echo "  ERREUR : impossible de joindre $BASE_URL/api/products"
  exit 1
}

if echo "$RESPONSE" | grep -q '"source":"database"'; then
  echo "  GET /api/products → PASS (source: database)"
  PRODUCT_COUNT=$(echo "$RESPONSE" | grep -o '"id":[0-9]*' | wc -l | tr -d ' ')
  echo "  Produits en base : $PRODUCT_COUNT"
else
  echo "  FAIL — réponse inattendue : $RESPONSE"
  exit 1
fi

# ─── ÉTAPE 5 : Provoquer l'incident (DROP TABLE) ─────────────────────────────
step "5 — INCIDENT CONTRÔLÉ : suppression de la table products"

echo "  Exécution : DROP TABLE products..."
docker exec shoplite_db \
  psql -U shoplite -d shoplite -c "DROP TABLE IF EXISTS products;"
echo "  Table products supprimée — incident actif."

# ─── ÉTAPE 6 : Constater que le test échoue ──────────────────────────────────
step "6 — Test /api/products PENDANT incident [attendu FAIL]"

HTTP_STATUS=$(curl -o /dev/null -w "%{http_code}" -fsS "$BASE_URL/api/products" 2>/dev/null || echo "000")
echo "  GET /api/products → HTTP $HTTP_STATUS"

if [ "$HTTP_STATUS" = "500" ] || [ "$HTTP_STATUS" = "000" ]; then
  echo "  Incident confirmé — endpoint dégradé comme prévu."
else
  echo "  Attention : code $HTTP_STATUS inattendu (attendu 500)."
fi

# ─── ÉTAPE 7 : Diagnostiquer ─────────────────────────────────────────────────
step "7 — Diagnostic"

echo "  Version déployée :"
docker inspect shoplite_api \
  --format '    Image : {{.Config.Image}} | Version : {{index .Config.Labels "org.opencontainers.image.version"}}' \
  2>/dev/null || echo "    (non disponible)"

echo ""
echo "  Derniers commits Git :"
git log --oneline -3 2>/dev/null || echo "    (non disponible)"

echo ""
echo "  Dernières erreurs dans les logs API :"
docker logs --tail 5 shoplite_api 2>&1 | grep -i "error\|500\|fail" || echo "    Aucune ligne d'erreur trouvée dans les 5 dernières lignes."

# ─── ÉTAPE 8 : Rollback sans supprimer les volumes ───────────────────────────
step "8 — Rollback vers $STABLE (sans docker compose down -v)"

sh "$(dirname "$0")/rollback.sh" "$STABLE" production

# ─── ÉTAPE 9 : Vérifier que le test repasse et les données existent ──────────
step "9 — Vérification finale [attendu PASS + données intactes]"

RESPONSE=$(curl -fsS "$BASE_URL/api/products" 2>/dev/null) || {
  echo "  ERREUR : /api/products toujours inaccessible après rollback"
  exit 1
}

if echo "$RESPONSE" | grep -q '"source":"database"'; then
  RESTORED_COUNT=$(echo "$RESPONSE" | grep -o '"id":[0-9]*' | wc -l | tr -d ' ')
  echo "  GET /api/products → PASS"
  echo "  Produits restaurés : $RESTORED_COUNT (était $PRODUCT_COUNT avant l'incident)"
  if [ "$RESTORED_COUNT" = "$PRODUCT_COUNT" ]; then
    echo "  Données intactes — aucune perte."
  else
    echo "  Attention : nombre de produits différent ($RESTORED_COUNT vs $PRODUCT_COUNT attendus)."
  fi
else
  echo "  FAIL — endpoint toujours dégradé après rollback"
  exit 1
fi

echo ""
echo "================================================"
echo "  SCÉNARIO TERMINÉ"
echo "  Incident simulé → diagnostiqué → rollback effectué"
echo "  Service restauré sur $BASE_URL"
echo "  Volumes PostgreSQL préservés"
echo "================================================"
