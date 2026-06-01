#!/usr/bin/env bash
# Apply all lolipants-api migrations to remote D1 (when wrangler times out).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXEC="$ROOT/scripts/d1-remote-exec.sh"
DB="lolipants-db"

bash "$EXEC" "$DB" --command \
  "CREATE TABLE IF NOT EXISTS d1_migrations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    applied_at TEXT NOT NULL DEFAULT (datetime('now'))
  );"

for f in "$ROOT"/migrations/*.sql; do
  name="$(basename "$f")"
  echo "Applying $name ..."
  bash "$EXEC" "$DB" "$f"
  bash "$EXEC" "$DB" --command \
    "INSERT INTO d1_migrations (name, applied_at) SELECT '${name}', datetime('now') WHERE NOT EXISTS (SELECT 1 FROM d1_migrations WHERE name = '${name}');"
done

echo "Done. Applied $(ls "$ROOT"/migrations/*.sql | wc -l) migrations."
