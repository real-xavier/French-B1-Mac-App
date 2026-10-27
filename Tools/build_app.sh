#!/bin/zsh
set -euo pipefail
PROJECT_DIR="${0:A:h:h}"
OUTPUT_DIR="/Users/xavier/Codex/2026-10-27/realtime-voice-chat/outputs"
APP_DIR="$OUTPUT_DIR/French B1.app"
cd "$PROJECT_DIR"
python3 Tools/import_vocabulary.py
python3 Tools/refresh_vocabulary_provenance.py
python3 Tools/validate_content.py
python3 Tools/build_verbs.py
python3 Tools/validate_verbs.py
export CLANG_MODULE_CACHE_PATH="/private/tmp/FrenchB1-clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="/private/tmp/FrenchB1-swift-cache"
swift build -c release -debug-info-format none --disable-sandbox --cache-path /private/tmp/FrenchB1-package-cache
BIN_DIR="$(swift build -c release -debug-info-format none --disable-sandbox --cache-path /private/tmp/FrenchB1-package-cache --show-bin-path)"
mkdir -p "$OUTPUT_DIR"
TEMP_APP="$OUTPUT_DIR/.French B1.build.app"
rm -rf "$TEMP_APP"
mkdir -p "$TEMP_APP/Contents/MacOS" "$TEMP_APP/Contents/Resources/Notices"
cp "$BIN_DIR/FrenchB1" "$TEMP_APP/Contents/MacOS/FrenchB1"
for resource in "$BIN_DIR"/*.bundle; do
    if [[ -d "$resource" ]]; then cp -R "$resource" "$TEMP_APP/Contents/Resources/"; fi
done
cp "$PROJECT_DIR/Documentation/Info.plist" "$TEMP_APP/Contents/Info.plist"
cp -R "$PROJECT_DIR/Resources" "$TEMP_APP/Contents/Resources/Notices/Editable linguistic resources"
cp -R "$PROJECT_DIR/Documentation" "$TEMP_APP/Contents/Resources/Notices/"
if [[ -f "$PROJECT_DIR/Resources/AppIcon.icns" ]]; then cp "$PROJECT_DIR/Resources/AppIcon.icns" "$TEMP_APP/Contents/Resources/AppIcon.icns"; fi
codesign --force --deep --sign - "$TEMP_APP"
if [[ -d "$APP_DIR" ]]; then rm -rf "$APP_DIR"; fi
mv "$TEMP_APP" "$APP_DIR"
codesign --verify --deep --strict "$APP_DIR"
/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$APP_DIR/Contents/Info.plist"
echo "$APP_DIR"
