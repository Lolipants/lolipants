#!/usr/bin/env bash
# Encodes local signing files for GitHub Actions secrets (run on your machine).
# Usage:
#   bash scripts/ci/encode_ios_secrets.sh ~/apple-signing/lolipants-distribution.p12 ~/apple-signing/Lolipants_App_Store.mobileprovision
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <distribution.p12> <profile.mobileprovision>" >&2
  exit 1
fi

P12="$1"
PROFILE="$2"

if [[ ! -f "${P12}" ]]; then
  echo "Missing .p12: ${P12}" >&2
  exit 1
fi

if [[ ! -f "${PROFILE}" ]]; then
  echo "Missing profile: ${PROFILE}" >&2
  exit 1
fi

encode() {
  if base64 --help 2>&1 | grep -q -- '-w'; then
    base64 -w 0 "$1"
  else
    base64 "$1" | tr -d '\n'
  fi
}

OUT_DIR="$(dirname "${P12}")"
P12_B64="${OUT_DIR}/ios-dist.p12.b64"
PROFILE_B64="${OUT_DIR}/ios-profile.b64"

encode "${P12}" >"${P12_B64}"
encode "${PROFILE}" >"${PROFILE_B64}"

echo "Wrote:"
echo "  ${P12_B64}  -> IOS_DIST_CERT_P12_BASE64"
echo "  ${PROFILE_B64}  -> IOS_PROVISIONING_PROFILE_BASE64"
echo
echo "Validate .p12 locally (enter export password when prompted):"
echo "  openssl pkcs12 -in \"${P12}\" -noout"
echo
echo "If that fails, re-export with AES-256-CBC (works on OpenSSL 3 + macOS CI):"
echo "  openssl pkcs12 -export -out new.p12 -inkey ios_distribution.key -in ios_distribution.pem \\"
echo "    -certpbe AES-256-CBC -keypbe AES-256-CBC -macalg SHA256"
