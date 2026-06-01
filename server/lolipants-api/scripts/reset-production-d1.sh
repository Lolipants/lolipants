#!/usr/bin/env bash
# Wipe remote D1 (app + auth), re-apply migrations, seed default accounts.
# Use when wrangler d1 execute / migrations apply time out (Windows); uses Cloudflare API.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXEC="$ROOT/scripts/d1-remote-exec.sh"
AUTH_ROOT="$(cd "$ROOT/../better-auth-worker" && pwd)"

echo "== Wipe lolipants-db =="
bash "$EXEC" lolipants-db "$ROOT/scripts/wipe-app-d1.sql" || true
# Fallback: drop tables individually if batch wipe hits FK errors
TOKEN="$(grep -m1 '^oauth_token' "${WRANGLER_CONFIG:-$HOME/AppData/Roaming/xdg.config/.wrangler/config/default.toml}" | cut -d'"' -f2)"
API_DB="c6e58a76-68b0-4f0b-a49c-233fafd9a1e2"
ACCOUNT="ed0f9a60460ec8572f9c24d4d91461ec"
for t in $(curl -sS -X POST "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT}/d1/database/${API_DB}/query" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"sql":"SELECT name FROM sqlite_master WHERE type='\''table'\'' AND name NOT IN ('\''sqlite_sequence'\'','\''_cf_KV'\'');"}' \
  | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{const j=JSON.parse(d);for(const r of j.result[0].results)console.log(r.name)})"); do
  [[ "$t" == "_cf_KV" ]] && continue
  curl -sS -X POST "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT}/d1/database/${API_DB}/query" \
    -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
    -d "{\"sql\":\"DROP TABLE IF EXISTS \\\"$t\\\";\"}" >/dev/null || true
  curl -sS -X POST "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT}/d1/database/${API_DB}/query" \
    -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
    -d "{\"sql\":\"DROP TABLE IF EXISTS $t;\"}" >/dev/null || true
done

echo "== Wipe lolipants_auth =="
for t in session account verification rateLimit user; do
  bash "$EXEC" lolipants_auth --command "DROP TABLE IF EXISTS \"$t\";"
done

echo "== Apply app migrations =="
bash "$ROOT/scripts/apply-migrations-remote.sh"

echo "== Apply auth migrations =="
bash "$EXEC" lolipants_auth "$AUTH_ROOT/migrations/0001_better_auth.sql"
bash "$EXEC" lolipants_auth "$AUTH_ROOT/migrations/0002_user_roles.sql"

echo "== Seed default accounts =="
cd "$ROOT" && pnpm seed:dev-accounts

echo "Production D1 reset complete."
