#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT_DIR/build"
APP_NAME="Mac Launcher"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
DMG_ROOT="$BUILD_DIR/dmg-root"
DMG_PATH="$BUILD_DIR/Mac-Launcher-1.5.6-arm64.dmg"
ICON_SOURCE="$ROOT_DIR/native/Assets/AppIcon.icns"

rm -rf "$APP_BUNDLE" "$DMG_ROOT"
mkdir -p "$CONTENTS_DIR/MacOS" "$CONTENTS_DIR/Resources" "$DMG_ROOT"

"$ROOT_DIR/scripts/check-lifecycle.sh"

CLANG_MODULE_CACHE_PATH="$BUILD_DIR/module-cache" clang \
  -fobjc-arc \
  -mmacosx-version-min=13.0 \
  "$ROOT_DIR/native/LauncherApp.m" \
  -framework Cocoa \
  -framework QuartzCore \
  -o "$CONTENTS_DIR/MacOS/MacLauncher"

ditto "$ROOT_DIR/native/Info.plist" "$CONTENTS_DIR/Info.plist"
ditto "$ICON_SOURCE" "$CONTENTS_DIR/Resources/AppIcon.icns"
plutil -lint "$CONTENTS_DIR/Info.plist"
codesign --force --deep --sign - "$APP_BUNDLE"

ditto "$APP_BUNDLE" "$DMG_ROOT/$APP_NAME.app"
ln -s /Applications "$DMG_ROOT/Applications"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_ROOT" \
  -format UDZO \
  -ov \
  "$DMG_PATH"

echo "Created: $DMG_PATH"
