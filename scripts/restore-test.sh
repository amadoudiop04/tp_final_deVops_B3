#!/bin/sh
set -eu

# ─── Configuration ────────────────────────────────────────────────────────────
CONTAINER="${DB_CONTAINER:-shoplite_db}"
DB_USER="${POSTGRES_USER:-shoplite}"
TEST_DB="shoplite_restore_test"
BACKUP_DIR="./backups"

# Fichier passé en argument ou dernier backup disponible
if [ $# -ge 1 ]; then
  BACKUP_FILE="$1"
else
  BACKUP_FILE=$(ls -1t "$BACKUP_DIR"/*.sql.gz 2>/dev/null | head -1 || true)
  [ -n "$BACKUP_FILE" ] || { echo "ERREUR : aucun backup trouvé dans $BACKUP_DIR/"; exit 1; }
fi

[ -f "$BACKUP_FILE" ] || { echo "ERREUR : fichier introuvable : $BACKUP_FILE"; exit 1; }

echo "=== Test de restauration ==="
echo "  Fichier   : $BACKUP_FILE"
echo "  Base test : $TEST_DB"
echo "  Conteneur : $CONTAINER"
echo ""

# ─── 1. Créer la base temporaire ─────────────────────────────────────────────
echo "[1/4] Suppression de la base temporaire (si elle existe)..."
docker exec "$CONTAINER" psql -U "$DB_USER" postgres \
  -c "DROP DATABASE IF EXISTS $TEST_DB;"

echo "[2/4] Création de la base temporaire : $TEST_DB"
docker exec "$CONTAINER" psql -U "$DB_USER" postgres \
  -c "CREATE DATABASE $TEST_DB;"

# ─── 2. Restaurer le dump ─────────────────────────────────────────────────────
echo "[3/4] Restauration du dump dans $TEST_DB..."
gunzip -c "$BACKUP_FILE" | docker exec -i "$CONTAINER" \
  psql -U "$DB_USER" -d "$TEST_DB" -q

# ─── 3. Valider la restauration ───────────────────────────────────────────────
echo "[4/4] Validation de la restauration..."
COUNT=$(docker exec "$CONTAINER" \
  psql -U "$DB_USER" -d "$TEST_DB" -t \
  -c "SELECT count(*) FROM products;" | tr -d ' \n')

echo ""
echo "  Produits restaurés : $COUNT"

EXIT_CODE=0
if [ "$COUNT" -gt 0 ]; then
  echo "  Statut : PASS — restauration validée"
else
  echo "  Statut : FAIL — aucun produit restauré"
  EXIT_CODE=1
fi

# ─── 4. Nettoyer — JAMAIS docker compose down -v ──────────────────────────────
echo ""
echo "[Cleanup] Suppression de la base temporaire $TEST_DB..."
docker exec "$CONTAINER" psql -U "$DB_USER" postgres \
  -c "DROP DATABASE IF EXISTS $TEST_DB;"
echo "  Base temporaire supprimée (données de production intactes)."

echo ""
if [ $EXIT_CODE -eq 0 ]; then
  echo "=== Restauration test : PASS ==="
else
  echo "=== Restauration test : FAIL ==="
fi

exit $EXIT_CODE
