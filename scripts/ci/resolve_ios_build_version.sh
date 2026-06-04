#!/usr/bin/env bash
# Sets BUILD_NAME and BUILD_NUMBER in GITHUB_ENV from pubspec + workflow context.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PUBSPEC="${ROOT}/pubspec.yaml"

VERSION_LINE="$(grep -E '^version:' "${PUBSPEC}" | head -1 | awk '{print $2}')"
PUBSPEC_NAME="${VERSION_LINE%%+*}"
PUBSPEC_NUMBER="${VERSION_LINE#*+}"

BUILD_NAME="${INPUT_BUILD_NAME:-}"
if [[ -z "${BUILD_NAME}" ]]; then
  if [[ "${GITHUB_REF_NAME:-}" =~ ^v[0-9] ]]; then
    BUILD_NAME="${GITHUB_REF_NAME#v}"
  else
    BUILD_NAME="${PUBSPEC_NAME}"
  fi
fi

BUILD_NUMBER="${INPUT_BUILD_NUMBER:-}"
if [[ -z "${BUILD_NUMBER}" ]]; then
  if [[ "${GITHUB_REF_NAME:-}" =~ ^v[0-9] ]] && [[ -n "${PUBSPEC_NUMBER}" ]]; then
    BUILD_NUMBER="${PUBSPEC_NUMBER}"
  else
    BUILD_NUMBER="${GITHUB_RUN_NUMBER:-${PUBSPEC_NUMBER:-1}}"
  fi
fi
if [[ -z "${BUILD_NUMBER}" ]]; then
  BUILD_NUMBER="1"
fi

{
  echo "BUILD_NAME=${BUILD_NAME}"
  echo "BUILD_NUMBER=${BUILD_NUMBER}"
} >>"${GITHUB_ENV:-/dev/null}"

echo "iOS build version: ${BUILD_NAME} (${BUILD_NUMBER})"
