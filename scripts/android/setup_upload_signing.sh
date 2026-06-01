#!/usr/bin/env bash
# Creates android/upload-keystore.jks and android/key.properties for Play Store release builds.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ANDROID_DIR="$ROOT/android"
KEYSTORE="$ANDROID_DIR/upload-keystore.jks"
PROPS="$ANDROID_DIR/key.properties"
EXAMPLE="$ANDROID_DIR/key.properties.example"
ALIAS="${KEYSTORE_ALIAS:-upload}"

if [[ -f "$PROPS" ]]; then
  echo "Already exists: $PROPS"
  echo "Release builds should use your upload keystore. To recreate, delete key.properties and upload-keystore.jks first."
  exit 0
fi

if [[ -f "$KEYSTORE" ]]; then
  echo "Found existing keystore: $KEYSTORE"
  echo "Enter the passwords for this keystore (they are only written to key.properties locally)."
else
  echo "No upload keystore yet. You will set passwords once — store them in a password manager."
  echo "If you lose this keystore, you cannot publish updates for the same Play app (unless Play support resets the upload key)."
fi

read -rsp "Keystore password: " STORE_PASS
echo
read -rsp "Key password [Enter = same as keystore]: " KEY_PASS
echo
KEY_PASS="${KEY_PASS:-$STORE_PASS}"

if [[ ! -f "$KEYSTORE" ]]; then
  keytool -genkey -v \
    -keystore "$KEYSTORE" \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -alias "$ALIAS" \
    -storepass "$STORE_PASS" \
    -keypass "$KEY_PASS" \
    -dname "CN=Lolipants, OU=Mobile, O=Lolipants, L=Unknown, ST=Unknown, C=US"
  echo "Created: $KEYSTORE"
fi

cat >"$PROPS" <<EOF
storePassword=$STORE_PASS
keyPassword=$KEY_PASS
keyAlias=$ALIAS
storeFile=../upload-keystore.jks
EOF
chmod 600 "$PROPS" 2>/dev/null || true

echo "Wrote: $PROPS"
echo
echo "SHA-1 for Google Cloud Android OAuth client (and Play Console):"
keytool -list -v -keystore "$KEYSTORE" -alias "$ALIAS" -storepass "$STORE_PASS" 2>/dev/null | grep -E "SHA1:|SHA-1:" || true
echo
echo "Verify release signing (no WARNING about key.properties):"
echo "  cd \"$ROOT\" && flutter build appbundle --release"
