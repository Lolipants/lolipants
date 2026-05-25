#!/usr/bin/env bash
# Writes the Flutter .env consumed at runtime (pubspec bundles it into the IPA).
# Values come from GitHub Actions secrets / repository variables.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_FILE="${ROOT}/.env"

required=(
  BETTER_AUTH_BASE_URL
  API_BASE_URL
  GOOGLE_SERVER_CLIENT_ID
  ONESIGNAL_APP_ID
)

for key in "${required[@]}"; do
  if [[ -z "${!key:-}" ]]; then
    echo "Missing required env var for release build: ${key}" >&2
    exit 1
  fi
done

cat >"${ENV_FILE}" <<EOF
BETTER_AUTH_BASE_URL=${BETTER_AUTH_BASE_URL}
API_BASE_URL=${API_BASE_URL}
GOOGLE_SERVER_CLIENT_ID=${GOOGLE_SERVER_CLIENT_ID}
ONESIGNAL_APP_ID=${ONESIGNAL_APP_ID}
TAP_PUBLIC_KEY=${TAP_PUBLIC_KEY:-}
BETTER_AUTH_ORIGIN=${BETTER_AUTH_ORIGIN:-${BETTER_AUTH_BASE_URL}}
CLOUDFLARE_API_BASE=${CLOUDFLARE_API_BASE:-}
CLOUDFLARE_R2_BASE_URL=${CLOUDFLARE_R2_BASE_URL:-}
EOF

echo "Wrote ${ENV_FILE} for release build."
