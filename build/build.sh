#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DIST_DIR="${REPO_DIR}/dist"
BUILD_DIR="${REPO_DIR}/build/.tmp"
OUTPUT_FILE="${DIST_DIR}/MinecraftBedrockUnlocker.exe"
RESOURCE_FILE="${BUILD_DIR}/launcher.res"
RC_FILE="${BUILD_DIR}/launcher.rc"

# Read version from single source of truth
VERSION="$(cat "${REPO_DIR}/VERSION" | tr -d '[:space:]')"
VERSION_4="${VERSION}.0"
echo "Building version ${VERSION} (${VERSION_4})..."

mkdir -p "${DIST_DIR}" "${BUILD_DIR}"

# Download latest DLLs from GitHub release for embedding (skip if already present)
if [ ! -f "${DIST_DIR}/OnlineFix64.dll" ]; then
  echo "Fetching DLLs from latest GitHub release..."
  gh release download --repo CoelhoFZ/MinecraftBedrockUnlocker --pattern '*.dll' --pattern 'dlllist.txt' --pattern 'OnlineFix.ini' --dir "${DIST_DIR}" 2>/dev/null || echo "  -> Could not auto-fetch DLLs. Place them in dist/ manually."
fi

# Substitute version into app.manifest
sed "s|3\.3\.3\.0|${VERSION_4}|g" "${REPO_DIR}/build/app.manifest" > "${BUILD_DIR}/app.manifest"

trap 'rm -f "${RESOURCE_FILE}" "${RC_FILE}" "${BUILD_DIR}/app.manifest"' EXIT

cat > "${RC_FILE}" <<EOF
1 RT_MANIFEST "${BUILD_DIR}/app.manifest"
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
  -resource:"${REPO_DIR}/unlocker.ps1,MinecraftBedrockUnlocker.Payload.unlocker.ps1" \
  -resource:"${REPO_DIR}/dist/OnlineFix64.dll,MinecraftBedrockUnlocker.Payload.OnlineFix64.dll" \
  -resource:"${REPO_DIR}/dist/winmm.dll,MinecraftBedrockUnlocker.Payload.winmm.dll" \
  -resource:"${REPO_DIR}/dist/dlllist.txt,MinecraftBedrockUnlocker.Payload.dlllist.txt" \
  -resource:"${REPO_DIR}/dist/OnlineFix.ini,MinecraftBedrockUnlocker.Payload.OnlineFix.ini" \
  "${REPO_DIR}/build/Launcher.cs"

file "${OUTPUT_FILE}"
