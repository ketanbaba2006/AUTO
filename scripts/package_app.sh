#!/bin/bash
set -e

# ==============================================================================
# AUTO macOS Application Packaging & DMG Distribution Script
# Fragment 7: Complete Integration, Packaging, and Release
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DIST_DIR="$PROJECT_ROOT/dist"
APP_BUNDLE="$DIST_DIR/AUTO.app"
DMG_FILE="$DIST_DIR/AUTO-1.0.0.dmg"

echo "======================================================="
echo "        PACKAGING AUTO NATIVE MACOS APPLICATION        "
echo "======================================================="

# Step 1: Clean and prepare distribution directory
echo "[1/6] Preparing distribution directory..."
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# Step 2: Build release binary using Swift Package Manager
echo "[2/6] Compiling AUTO in Release configuration..."
cd "$PROJECT_ROOT"
swift build -c release

RELEASE_BIN="$PROJECT_ROOT/.build/release/AUTO"
if [ ! -f "$RELEASE_BIN" ]; then
    echo "ERROR: Release binary not found at $RELEASE_BIN"
    exit 1
fi

# Step 3: Construct macOS App Bundle
echo "[3/6] Assembling AUTO.app bundle..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp "$RELEASE_BIN" "$APP_BUNDLE/Contents/MacOS/AUTO"
chmod +x "$APP_BUNDLE/Contents/MacOS/AUTO"

# Copy Info.plist
cp "$PROJECT_ROOT/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# Create PkgInfo
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# Copy Icon
if [ -f "$PROJECT_ROOT/AUTO/Resources/AUTO.icns" ]; then
    cp "$PROJECT_ROOT/AUTO/Resources/AUTO.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

# Copy SPM resource bundle if present
RESOURCE_BUNDLE="$PROJECT_ROOT/.build/release/AUTO_AUTO.bundle"
if [ -d "$RESOURCE_BUNDLE" ]; then
    cp -R "$RESOURCE_BUNDLE" "$APP_BUNDLE/Contents/Resources/"
fi

# Step 4: Ad-hoc code signing
echo "[4/6] Code signing bundle..."
if [ -f "$PROJECT_ROOT/AUTO.entitlements" ]; then
    codesign --force --deep --sign - --entitlements "$PROJECT_ROOT/AUTO.entitlements" "$APP_BUNDLE"
else
    codesign --force --deep --sign - "$APP_BUNDLE"
fi

codesign -v "$APP_BUNDLE"
echo "  [SUCCESS] Code signature verified."

# Step 5: Generate DMG Installer
echo "[5/6] Creating disk image (AUTO-1.0.0.dmg)..."
DMG_STAGING="$DIST_DIR/dmg_staging"
mkdir -p "$DMG_STAGING"
cp -R "$APP_BUNDLE" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

hdiutil create \
    -volname "AUTO" \
    -srcfolder "$DMG_STAGING" \
    -ov \
    -format UDZO \
    "$DMG_FILE"

rm -rf "$DMG_STAGING"

# Step 6: Verification Summary
echo "[6/6] Verifying distribution artifacts..."
echo "-------------------------------------------------------"
echo "Application Bundle : $APP_BUNDLE"
echo "Bundle Size        : $(du -sh "$APP_BUNDLE" | cut -f1)"
echo "DMG Installer      : $DMG_FILE"
echo "DMG Size           : $(du -sh "$DMG_FILE" | cut -f1)"
echo "======================================================="
echo "AUTO PACKAGING COMPLETED SUCCESSFULLY!"
echo "======================================================="

