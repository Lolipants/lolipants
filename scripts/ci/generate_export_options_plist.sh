#!/usr/bin/env bash
# Generates ios/ExportOptions.plist for App Store export on CI.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="${ROOT}/ios/ExportOptions.plist"

if [[ -z "${IOS_TEAM_ID:-}" ]]; then
  echo "IOS_TEAM_ID is required." >&2
  exit 1
fi

BUNDLE_ID="${IOS_BUNDLE_ID:-com.lolipants.lolipants}"
PROFILE_NAME="${IOS_PROVISIONING_PROFILE_NAME:-}"

SIGNING_STYLE="automatic"
PROFILE_BLOCK=""

if [[ -n "${PROFILE_NAME}" ]]; then
  SIGNING_STYLE="manual"
  PROFILE_BLOCK="$(cat <<PLIST
	<key>provisioningProfiles</key>
	<dict>
		<key>${BUNDLE_ID}</key>
		<string>${PROFILE_NAME}</string>
	</dict>
PLIST
)"
fi

cat >"${OUT}" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>app-store</string>
	<key>teamID</key>
	<string>${IOS_TEAM_ID}</string>
	<key>signingStyle</key>
	<string>${SIGNING_STYLE}</string>
	<key>uploadSymbols</key>
	<true/>
	<key>compileBitcode</key>
	<false/>
${PROFILE_BLOCK}
</dict>
</plist>
PLIST

echo "Wrote ${OUT}"
