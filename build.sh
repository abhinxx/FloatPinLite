#!/bin/bash
# Builds FloatPinLite.app with just the Xcode command line tools (no Xcode needed).
#   ./build.sh            build into ./build/FloatPinLite.app
#   ./build.sh install    build, copy to /Applications, and launch
# Set SIGN_IDENTITY to your "Apple Development: ..." cert so macOS keeps your
# permissions between rebuilds. Default is ad-hoc signing (permissions reset).
set -euo pipefail
cd "$(dirname "$0")"

APP="build/FloatPinLite.app"
rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/"

swiftc -O -target "$(uname -m)-apple-macos14.0" \
  -framework AppKit -framework ScreenCaptureKit \
  -framework Carbon -framework ServiceManagement \
  -Xlinker -dead_strip \
  Sources/*.swift -o "$APP/Contents/MacOS/FloatPinLite"
strip -x "$APP/Contents/MacOS/FloatPinLite"
codesign --force --sign "${SIGN_IDENTITY:--}" "$APP"
echo "Built $APP"

if [[ "${1:-}" == "install" ]]; then
  pkill -x FloatPinLite 2>/dev/null || true
  rm -rf /Applications/FloatPinLite.app
  cp -R "$APP" /Applications/
  open /Applications/FloatPinLite.app
  echo "Installed to /Applications and launched."
fi
