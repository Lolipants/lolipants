#!/usr/bin/env bash
# camera_avfoundation 0.10.1 uses AVCaptureSession.*Notification APIs removed in
# Xcode 16 / iOS 18 SDK. Patch to NSNotification.Name string constants.
set -euo pipefail

PUB_CACHE="${PUB_CACHE:-${HOME}/.pub-cache}"
mapfile -t targets < <(
  find "${PUB_CACHE}/hosted/pub.dev" -path "*/camera_avfoundation-*/ios/camera_avfoundation/Sources/camera_avfoundation/*.swift" \
    -print 2>/dev/null || true
)

if [[ ${#targets[@]} -eq 0 ]]; then
  echo "No camera_avfoundation Swift sources found in ${PUB_CACHE}; skipping patch."
  exit 0
fi

patched=0
for file in "${targets[@]}"; do
  if grep -q 'AVCaptureSession\.wasInterruptedNotification\|AVCaptureSession\.runtimeErrorNotification' "${file}"; then
    sed -i.bak \
      -e 's/AVCaptureSession\.wasInterruptedNotification/NSNotification.Name("AVCaptureSessionWasInterruptedNotification")/g' \
      -e 's/AVCaptureSession\.runtimeErrorNotification/NSNotification.Name("AVCaptureSessionRuntimeErrorNotification")/g' \
      "${file}"
    rm -f "${file}.bak"
    echo "Patched ${file}"
    patched=$((patched + 1))
  fi
done

if [[ "${patched}" -eq 0 ]]; then
  echo "camera_avfoundation already patched or uses compatible notification names."
else
  echo "Patched ${patched} camera_avfoundation file(s) for Xcode 16."
fi
