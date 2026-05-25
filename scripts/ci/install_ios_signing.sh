#!/usr/bin/env bash
# Imports the distribution certificate + App Store provisioning profile into the
# macOS keychain used by GitHub Actions runners.
set -euo pipefail

decode_base64() {
  # GitHub secrets may contain wrapped base64 from Windows `base64` without -w 0.
  tr -d '[:space:]' | base64 -D
}

fail() {
  echo "Install Apple signing assets failed: $*" >&2
  exit 1
}

if [[ -z "${IOS_DIST_CERT_P12_BASE64:-}" || -z "${IOS_DIST_CERT_PASSWORD:-}" ]]; then
  fail "IOS_DIST_CERT_P12_BASE64 and IOS_DIST_CERT_PASSWORD are required."
fi

if [[ -z "${IOS_PROVISIONING_PROFILE_BASE64:-}" ]]; then
  fail "IOS_PROVISIONING_PROFILE_BASE64 is required."
fi

KEYCHAIN_PATH="${RUNNER_TEMP:-/tmp}/app-signing.keychain-db"
KEYCHAIN_PASSWORD="$(openssl rand -base64 32)"

security create-keychain -p "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_PATH}"
security set-keychain-settings -lut 21600 "${KEYCHAIN_PATH}"
security unlock-keychain -p "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_PATH}"
security default-keychain -s "${KEYCHAIN_PATH}"

CERT_PATH="${RUNNER_TEMP}/distribution.p12"
if ! printf '%s' "${IOS_DIST_CERT_P12_BASE64}" | decode_base64 >"${CERT_PATH}"; then
  fail "Could not decode IOS_DIST_CERT_P12_BASE64. Re-encode with: base64 -w 0 cert.p12 | tr -d '\\n'"
fi

if [[ ! -s "${CERT_PATH}" ]]; then
  fail "Decoded .p12 is empty. Check IOS_DIST_CERT_P12_BASE64."
fi

validate_p12() {
  openssl pkcs12 -in "${CERT_PATH}" -passin "pass:${IOS_DIST_CERT_PASSWORD}" -noout "$@" 2>/dev/null
}

if validate_p12; then
  echo "Validated .p12 (modern algorithms)."
elif validate_p12 -legacy; then
  echo "Validated .p12 (legacy algorithms — macOS import may still work)."
else
  fail "Invalid .p12 or wrong IOS_DIST_CERT_PASSWORD. Re-export with AES-256-CBC (see docs/ios-github-actions.md)."
fi

if ! security import "${CERT_PATH}" -P "${IOS_DIST_CERT_PASSWORD}" -A -t cert -f pkcs12 -k "${KEYCHAIN_PATH}"; then
  fail "macOS keychain rejected the .p12. Re-export with AES-256-CBC (see docs/ios-github-actions.md)."
fi

security list-keychain -d user -s "${KEYCHAIN_PATH}"
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_PATH}"

PROFILE_PATH="${RUNNER_TEMP}/appstore.mobileprovision"
if ! printf '%s' "${IOS_PROVISIONING_PROFILE_BASE64}" | decode_base64 >"${PROFILE_PATH}"; then
  fail "Could not decode IOS_PROVISIONING_PROFILE_BASE64."
fi

if [[ ! -s "${PROFILE_PATH}" ]]; then
  fail "Decoded provisioning profile is empty."
fi

PROFILE_PLIST="$(security cms -D -i "${PROFILE_PATH}" 2>/dev/null || true)"
if [[ -z "${PROFILE_PLIST}" ]]; then
  fail "Provisioning profile is not a valid .mobileprovision file."
fi

PROFILE_DIR="${HOME}/Library/MobileDevice/Provisioning Profiles"
mkdir -p "${PROFILE_DIR}"

PROFILE_UUID="$(
  /usr/libexec/PlistBuddy -c 'Print :UUID' /dev/stdin <<<"${PROFILE_PLIST}"
)"
cp "${PROFILE_PATH}" "${PROFILE_DIR}/${PROFILE_UUID}.mobileprovision"

PROFILE_NAME="$(
  /usr/libexec/PlistBuddy -c 'Print :Name' /dev/stdin <<<"${PROFILE_PLIST}"
)"

echo "Installed provisioning profile: ${PROFILE_NAME} (${PROFILE_UUID})"
echo "IOS_PROVISIONING_PROFILE_NAME=${PROFILE_NAME}" >>"${GITHUB_ENV:-/dev/null}"
