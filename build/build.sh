#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DIST_DIR="${REPO_DIR}/dist"
BUILD_DIR="${REPO_DIR}/build/.tmp"
OUTPUT_FILE="${DIST_DIR}/MinecraftBedrockUnlocker.exe"
RESOURCE_FILE="${BUILD_DIR}/launcher.res"
RC_FILE="${BUILD_DIR}/launcher.rc"

mkdir -p "${DIST_DIR}" "${BUILD_DIR}"
trap 'rm -f "${RESOURCE_FILE}" "${RC_FILE}"' EXIT

cat > "${RC_FILE}" <<EOF
1 RT_MANIFEST "${REPO_DIR}/build/app.manifest"
1 ICON "${REPO_DIR}/icon.ico"
EOF

x86_64-w64-mingw32-windres \
  --input-format=rc \
  --output-format=res \
  --output="${RESOURCE_FILE}" \
  "${RC_FILE}"

mcs \
  -nologo \
  -optimize+ \
  -platform:x64 \
  -target:exe \
  -sdk:4.5 \
  -out:"${OUTPUT_FILE}" \
  -win32res:"${RESOURCE_FILE}" \
  -resource:"${REPO_DIR}/install.ps1,MinecraftBedrockUnlocker.Payload.install.ps1" \
  "${REPO_DIR}/build/Launcher.cs"

file "${OUTPUT_FILE}"
