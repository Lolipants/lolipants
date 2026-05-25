#!/usr/bin/env bash
# Unlocks the CI signing keychain before xcodebuild / flutter build ipa.
set -euo pipefail

if [[ -z "${KEYCHAIN_PATH:-}" || -z "${KEYCHAIN_PASSWORD:-}" ]]; then
  echo "KEYCHAIN_PATH and KEYCHAIN_PASSWORD must be set (from install_ios_signing.sh)." >&2
  exit 1
fi

security unlock-keychain -p "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_PATH}"
security list-keychain -d user -s "${KEYCHAIN_PATH}"
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_PATH}" || true

echo "Signing keychain ready: ${KEYCHAIN_PATH}"
