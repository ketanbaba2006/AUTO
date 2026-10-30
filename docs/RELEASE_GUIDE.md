# AUTO Release & Distribution Guide

## 1. Release Architecture

AUTO is packaged into two official distribution formats:
1. **`AUTO.app`**: Native standalone macOS Application Bundle (16 MB).
2. **`AUTO-1.0.0.dmg`**: Compressed Apple Disk Image installer with `/Applications` shortcut (11 MB).

---

## 2. Automated Packaging Pipeline

To generate release artifacts, run the master packaging script from the project root:

```bash
./scripts/package_app.sh
```

### Script Execution Stages:
1. **Clean Distribution Directory**: Resets `dist/`.
2. **Release Compilation**: Executes `swift build -c release` with full Swift compiler optimizations (`-O`).
3. **App Bundle Assembly**: Creates `AUTO.app/Contents/MacOS` and `AUTO.app/Contents/Resources`.
4. **Asset & Icon Embedding**: Embeds `Info.plist`, `PkgInfo`, `AppIcon.icns`, and SPM asset bundles.
5. **Code Signing**: Applies ad-hoc signature with entitlements (`AUTO.entitlements`).
6. **DMG Generation**: Creates a read-only compressed UDZO disk image using native macOS `hdiutil`.

---

## 3. Code Signing & Notarization Options

### Option A: Ad-Hoc Signing (Default / Independent Distribution)
Included in the packaging script:
```bash
codesign --force --deep --sign - --entitlements AUTO.entitlements dist/AUTO.app
```
- Requires no paid developer account.
- Works immediately on any Mac running macOS 14.0+.
- First launch requires the standard user confirmation (Right-click -> Open).

### Option B: Apple Developer ID & Notarization (Commercial Distribution)
If you hold an active Apple Developer Program membership:

1. **Sign with Developer ID Application Certificate**:
```bash
codesign --force --deep --options runtime \
  --sign "Developer ID Application: Your Name (TEAMID)" \
  --entitlements AUTO.entitlements \
  dist/AUTO.app
```

2. **Submit to Apple Notary Service**:
```bash
xcrun notarytool submit dist/AUTO-1.0.0.dmg \
  --keychain-profile "AC_NOTARY" \
  --wait
```

3. **Staple Ticket to DMG**:
```bash
xcrun stapler staple dist/AUTO-1.0.0.dmg
```

---

## 4. Pre-Release Quality Verification Checklist

Before publishing any new version:
- [x] All 84 automated unit and integration tests pass cleanly (`./.build/debug/AUTO --test`).
- [x] App builds with zero compiler warnings in Release configuration.
- [x] High-resolution mascot logo and icon render in Menu Bar, Dock, and Floating Panel.
- [x] Push-to-Talk modifier event tap functions without duplicate event loops.
- [x] Screen captures are strictly ephemeral and discarded from RAM immediately.
- [x] Memory manager sensitive data scanner rejects passwords and credentials.
- [x] Emergency Stop halts simulated actions in under 10 milliseconds.
- [x] No accounts, paywalls, premium gates, or subscriptions exist.

