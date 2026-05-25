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

write_password_file() {
  local path="${RUNNER_TEMP}/p12-password.txt"
  printf '%s' "${IOS_DIST_CERT_PASSWORD}" >"${path}"
  echo "${path}"
}

run_openssl_pkcs12() {
  local password_file="$1"
  shift
  openssl pkcs12 -passin "file:${password_file}" "$@"
}

if [[ -z "${IOS_DIST_CERT_P12_BASE64:-}" || -z "${IOS_DIST_CERT_PASSWORD:-}" ]]; then
  fail "IOS_DIST_CERT_P12_BASE64 and IOS_DIST_CERT_PASSWORD are required."
fi

# GitHub secrets occasionally include a trailing newline.
IOS_DIST_CERT_PASSWORD="${IOS_DIST_CERT_PASSWORD//$'\n'/}"
IOS_DIST_CERT_PASSWORD="${IOS_DIST_CERT_PASSWORD//$'\r'/}"

if [[ -z "${IOS_PROVISIONING_PROFILE_BASE64:-}" ]]; then
  fail "IOS_PROVISIONING_PROFILE_BASE64 is required."
fi

KEYCHAIN_PATH="${RUNNER_TEMP:-/tmp}/app-signing.keychain-db"
KEYCHAIN_PASSWORD="$(openssl rand -base64 32)"
PASSWORD_FILE="$(write_password_file)"

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
  run_openssl_pkcs12 "${PASSWORD_FILE}" -in "${CERT_PATH}" -noout "$@" 2>/dev/null
}

extract_p12_material() {
  local cert_pem="$1"
  local key_pem="$2"

  if run_openssl_pkcs12 "${PASSWORD_FILE}" -in "${CERT_PATH}" -clcerts -nokeys -out "${cert_pem}"; then
    :
  elif run_openssl_pkcs12 "${PASSWORD_FILE}" -legacy -in "${CERT_PATH}" -clcerts -nokeys -out "${cert_pem}"; then
    :
  else
    return 1
  fi

  if run_openssl_pkcs12 "${PASSWORD_FILE}" -in "${CERT_PATH}" -nocerts -nodes -out "${key_pem}"; then
    :
  elif run_openssl_pkcs12 "${PASSWORD_FILE}" -legacy -in "${CERT_PATH}" -nocerts -nodes -out "${key_pem}"; then
    :
  else
    return 1
  fi
}

import_wwdr_certificate() {
  local wwdr_cer="${RUNNER_TEMP}/AppleWWDRCAG3.cer"
  local wwdr_pem="${RUNNER_TEMP}/AppleWWDRCAG3.pem"

  if ! curl -fsSL "https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer" -o "${wwdr_cer}"; then
    echo "Warning: could not download Apple WWDR intermediate certificate." >&2
    return 0
  fi

  openssl x509 -inform der -in "${wwdr_cer}" -out "${wwdr_pem}"
  security import "${wwdr_pem}" -k "${KEYCHAIN_PATH}" -A \
    -T /usr/bin/codesign -T /usr/bin/security -T /usr/bin/productbuild || true
}

import_distribution_p12() {
  local p12_path="$1"
  local cert_pem="${RUNNER_TEMP}/distribution-cert.pem"
  local key_pem="${RUNNER_TEMP}/distribution-key.pem"

  if security import "${p12_path}" -P "${IOS_DIST_CERT_PASSWORD}" -A -t cert -f pkcs12 -k "${KEYCHAIN_PATH}" 2>/dev/null; then
    echo "Imported .p12 into keychain."
    return 0
  fi

  echo "Direct .p12 import failed; importing certificate + private key separately…" >&2

  if ! extract_p12_material "${cert_pem}" "${key_pem}"; then
    fail "Could not extract certificate/private key from .p12. Check IOS_DIST_CERT_PASSWORD."
  fi

  security import "${cert_pem}" -k "${KEYCHAIN_PATH}" -A \
    -T /usr/bin/codesign -T /usr/bin/security -T /usr/bin/productbuild \
    || fail "Could not import distribution certificate into keychain."

  security import "${key_pem}" -k "${KEYCHAIN_PATH}" -A \
    -T /usr/bin/codesign -T /usr/bin/security -T /usr/bin/productbuild \
    || fail "Could not import distribution private key into keychain."

  import_wwdr_certificate
  echo "Imported distribution certificate and private key into keychain."
}

if validate_p12; then
  echo "Validated .p12 (modern algorithms)."
elif validate_p12 -legacy; then
  echo "Validated .p12 (legacy algorithms)."
else
  fail "Invalid .p12 or wrong IOS_DIST_CERT_PASSWORD."
fi

import_distribution_p12 "${CERT_PATH}"

security list-keychain -d user -s "${KEYCHAIN_PATH}"
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_PATH}"

{
  echo "KEYCHAIN_PATH=${KEYCHAIN_PATH}"
  echo "KEYCHAIN_PASSWORD=${KEYCHAIN_PASSWORD}"
} >>"${GITHUB_ENV:-/dev/null}"

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
