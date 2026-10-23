#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_DIR}"

echo "==> Compilando OrbitDropApp em modo release..."
swift build -c release

BUILD_BIN="${PROJECT_DIR}/.build/release/OrbitDropApp"
APP_DIR="${PROJECT_DIR}/build/OrbitDrop.app"

echo "==> Montando bundle ${APP_DIR}..."
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

cp "${BUILD_BIN}" "${APP_DIR}/Contents/MacOS/OrbitDropApp"
chmod +x "${APP_DIR}/Contents/MacOS/OrbitDropApp"

cat << 'PLIST' > "${APP_DIR}/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>OrbitDropApp</string>
    <key>CFBundleIdentifier</key>
    <string>com.orbitdrop.app</string>
    <key>CFBundleName</key>
    <string>OrbitDrop</string>
    <key>CFBundleDisplayName</key>
    <string>OrbitDrop</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>© 2026 OrbitDrop Project. Código aberto e ilimitado.</string>
</dict>
</plist>
PLIST

echo "==> Assinando bundle ad-hoc com entitlements de segurança..."
ENTITLEMENTS="${PROJECT_DIR}/Distribution/OrbitDrop.entitlements"
if [ -f "${ENTITLEMENTS}" ]; then
    codesign -s - --force --deep --entitlements "${ENTITLEMENTS}" "${APP_DIR}"
else
    codesign -s - --force --deep "${APP_DIR}"
fi

echo "==> Sucesso! Aplicativo empacotado em: ${APP_DIR}"
