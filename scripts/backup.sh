#!/bin/sh
set -eu

# ─── Configuration ────────────────────────────────────────────────────────────
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
CONTAINER="${DB_CONTAINER:-shoplite_db}"
DB_NAME="${POSTGRES_DB:-shoplite}"
DB_USER="${POSTGRES_USER:-shoplite}"
BACKUP_DIR="./backups"
FILENAME="${DB_NAME}_${TIMESTAMP}.sql.gz"
RETENTION="${BACKUP_RETENTION:-7}"

mkdir -p "$BACKUP_DIR"

echo "=== Backup ShopLite — $TIMESTAMP ==="
echo "  Conteneur : $CONTAINER"
echo "  Base      : $DB_NAME"
echo "  Fichier   : $BACKUP_DIR/$FILENAME"

# ─── pg_dump via le conteneur, compression gzip sur l'hôte ──────────────────
docker exec "$CONTAINER" pg_dump -U "$DB_USER" "$DB_NAME" \
  | gzip > "$BACKUP_DIR/$FILENAME"

SIZE=$(du -h "$BACKUP_DIR/$FILENAME" | cut -f1)
echo "  Taille    : $SIZE"
echo "  Sauvegarde créée avec succès."

# ─── Politique de rétention : conserver les $RETENTION derniers backups ──────
TOTAL=$(ls -1 "$BACKUP_DIR"/*.sql.gz 2>/dev/null | wc -l | tr -d ' ')
echo ""
echo "  Rétention : $TOTAL backup(s) présent(s) / maximum $RETENTION"

if [ "$TOTAL" -gt "$RETENTION" ]; then
  TO_DELETE=$(( TOTAL - RETENTION ))
  echo "  Suppression de $TO_DELETE ancien(s) backup(s)..."
  ls -1t "$BACKUP_DIR"/*.sql.gz | tail -n "$TO_DELETE" | while IFS= read -r old_file; do
    rm -f "$old_file"
    echo "    Supprimé : $old_file"
  done
fi

REMAINING=$(ls -1 "$BACKUP_DIR"/*.sql.gz 2>/dev/null | wc -l | tr -d ' ')
echo "  Backups conservés : $REMAINING / $RETENTION"
echo "=== Backup terminé : $FILENAME ==="
