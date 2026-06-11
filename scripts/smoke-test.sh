#!/bin/sh
# Smoke test post-déploiement — ShopLite
# Usage : BASE_URL=http://localhost:8081 sh scripts/smoke-test.sh
set -eu

BASE_URL="${BASE_URL:-http://localhost:8080}"
OK=0
FAIL=0

check() {
  label="$1"
  url="$2"
  expect="$3"
  body=$(curl -fsS --max-time 5 "$url" 2>/dev/null) || {
    echo "  FAIL  $label — connexion impossible ($url)"
    FAIL=$((FAIL + 1))
    return
  }
  if echo "$body" | grep -q "$expect"; then
    echo "  OK    $label"
    OK=$((OK + 1))
  else
    echo "  FAIL  $label — réponse inattendue"
    echo "        attendu  : $expect"
    echo "        reçu     : $body"
    FAIL=$((FAIL + 1))
  fi
}

echo "================================================"
echo "  Smoke test — $BASE_URL"
echo "================================================"

check "GET /api/ready   → status ready"    "$BASE_URL/api/ready"    '"status":"ready"'
check "GET /api/health  → status ok"       "$BASE_URL/api/health"   '"status":"ok"'
check "GET /api/health  → db ok"           "$BASE_URL/api/health"   '"database":"ok"'
check "GET /api/products → source db"      "$BASE_URL/api/products" '"source":"database"'
check "GET /api/products → tableau data"   "$BASE_URL/api/products" '"data":\['

echo "================================================"
echo "  Résultat : $OK OK / $((OK + FAIL)) tests"
echo "================================================"

[ "$FAIL" -eq 0 ] || { echo "ECHEC — $FAIL test(s) en erreur"; exit 1; }
echo "Smoke test PASS"
