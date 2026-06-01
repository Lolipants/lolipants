#!/usr/bin/env bash
# Run SQL against remote D1 via Cloudflare API (workaround when wrangler d1 execute times out).
set -euo pipefail

DB_NAME="${1:?usage: d1-remote-exec.sh <lolipants-db|lolipants_auth> <sql-file|--command SQL>}"
shift

ACCOUNT_ID="ed0f9a60460ec8572f9c24d4d91461ec"
case "$DB_NAME" in
  lolipants-db) DB_ID="c6e58a76-68b0-4f0b-a49c-233fafd9a1e2" ;;
  lolipants_auth) DB_ID="ad8341b5-e383-4ea6-b79b-3f17d08ed169" ;;
  *) echo "Unknown database: $DB_NAME" >&2; exit 1 ;;
esac

WRANGLER_CONFIG="${WRANGLER_CONFIG:-$HOME/AppData/Roaming/xdg.config/.wrangler/config/default.toml}"
if [[ ! -f "$WRANGLER_CONFIG" ]]; then
  WRANGLER_CONFIG="$HOME/.wrangler/config/default.toml"
fi
TOKEN="$(grep -m1 '^oauth_token' "$WRANGLER_CONFIG" | cut -d'"' -f2)"
if [[ -z "$TOKEN" ]]; then
  echo "No oauth_token in $WRANGLER_CONFIG — run: npx wrangler login" >&2
  exit 1
fi

URL="https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/d1/database/${DB_ID}/query"

run_sql() {
  local sql="$1"
  local payload
  payload="$(printf '%s' "$sql" | node -e "let s='';process.stdin.on('data',d=>s+=d);process.stdin.on('end',()=>process.stdout.write(JSON.stringify({sql:s})))")"
  local resp
  resp="$(curl -sS --max-time 120 -X POST "$URL" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "$payload")"
  if ! echo "$resp" | node -e "
    let d=''; process.stdin.on('data',c=>d+=c);
    process.stdin.on('end',()=>{
      const j=JSON.parse(d);
      if(!j.success){ console.error(JSON.stringify(j,null,2)); process.exit(1); }
    });
  "; then
    echo "$resp" >&2
    exit 1
  fi
  echo "$resp"
}

if [[ "${1:-}" == "--command" ]]; then
  run_sql "${2:?missing SQL}"
  exit 0
fi

FILE="${1:?missing sql file}"
run_sql "$(cat "$FILE")"
