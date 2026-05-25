#!/usr/bin/env bash
# Imports the distribution certificate + App Store provisioning profile into the
# macOS keychain used by GitHub Actions runners.
set -euo pipefail

if [[ -z "${IOS_DIST_CERT_P12_BASE64:-}" || -z "${IOS_DIST_CERT_PASSWORD:-}" ]]; then
  echo "IOS_DIST_CERT_P12_BASE64 and IOS_DIST_CERT_PASSWORD are required." >&2
  exit 1
fi

if [[ -z "${IOS_PROVISIONING_PROFILE_BASE64:-}" ]]; then
  echo "IOS_PROVISIONING_PROFILE_BASE64 is required." >&2
  exit 1
fi

KEYCHAIN_PATH="${RUNNER_TEMP:-/tmp}/app-signing.keychain-db"
KEYCHAIN_PASSWORD="$(openssl rand -base64 32)"

security create-keychain -p "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_PATH}"
security set-keychain-settings -lut 21600 "${KEYCHAIN_PATH}"
security unlock-keychain -p "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_PATH}"

CERT_PATH="${RUNNER_TEMP}/distribution.p12"
echo "${IOS_DIST_CERT_P12_BASE64}" | base64 -D >"${CERT_PATH}"
security import "${CERT_PATH}" -P "${IOS_DIST_CERT_PASSWORD}" -A -t cert -f pkcs12 -k "${KEYCHAIN_PATH}"
security list-keychain -d user -s "${KEYCHAIN_PATH}" login.keychain
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_PATH}"

PROFILE_PATH="${RUNNER_TEMP}/appstore.mobileprovision"
echo "${IOS_PROVISIONING_PROFILE_BASE64}" | base64 -D >"${PROFILE_PATH}"

PROFILE_DIR="${HOME}/Library/MobileDevice/Provisioning Profiles"
mkdir -p "${PROFILE_DIR}"

PROFILE_UUID="$(
  /usr/libexec/PlistBuddy -c 'Print :UUID' /dev/stdin \
    <<<"$(security cms -D -i "${PROFILE_PATH}")"
)"
cp "${PROFILE_PATH}" "${PROFILE_DIR}/${PROFILE_UUID}.mobileprovision"

PROFILE_NAME="$(
  /usr/libexec/PlistBuddy -c 'Print :Name' /dev/stdin \
    <<<"$(security cms -D -i "${PROFILE_PATH}")"
)"

echo "Installed provisioning profile: ${PROFILE_NAME} (${PROFILE_UUID})"
echo "IOS_PROVISIONING_PROFILE_NAME=${PROFILE_NAME}" >>"${GITHUB_ENV:-/dev/null}"
