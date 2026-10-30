# AUTO macOS Code Signing Guide

## 1. Code Signing Overview

macOS Gatekeeper requires applications to be signed to verify bundle integrity and protect against malicious tampering.

AUTO supports two code-signing tiers:
1. **Ad-Hoc Signing (Default / Open Source)**: Requires no paid developer account. Allows immediate local compilation and distribution.
2. **Apple Developer ID Application Signing**: Required for commercial or zero-prompt Gatekeeper distribution.

---

## 2. Hardened Runtime Entitlements

AUTO utilizes a hardened entitlements file ([`AUTO.entitlements`](file:///Users/ketanbaba/Desktop/Extra/AUTO/AUTO.entitlements)):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.device.audio-input</key>
    <true/>
    <key>com.apple.security.device.microphone</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.keychain</key>
    <true/>
    <key>com.apple.security.automation.apple-events</key>
    <true/>
    <key>com.apple.security.personal-information.speech-recognition</key>
    <true/>
</dict>
</plist>
```

---

## 3. Tier 1: Ad-Hoc Signing (Current Configuration)

Executed automatically by `scripts/package_app.sh`:

```bash
codesign --force --deep --sign - --entitlements AUTO.entitlements dist/AUTO.app
```

### Verification:
```bash
codesign -v dist/AUTO.app
codesign -d --entitlements :- dist/AUTO.app
```

### User Installation Experience:
Because the application is signed with an ad-hoc certificate rather than an Apple-issued Developer ID, Gatekeeper will show a standard prompt on first launch. Users simply right-click `AUTO.app` in `/Applications` and select **Open**.

---

## 4. Tier 2: Apple Developer ID Signing (Production Deployment)

When deploying with an active Apple Developer Program certificate:

### 1. Identify Certificate in Keychain:
```bash
security find-identity -p codesigning -v
```
Look for: `Developer ID Application: Your Name (TEAMID)`.

### 2. Sign the Bundle with Hardened Runtime:
```bash
codesign --force --deep --options runtime \
  --sign "Developer ID Application: Your Name (TEAMID)" \
  --entitlements AUTO.entitlements \
  dist/AUTO.app
```

### 3. Verify Signature:
```bash
spctl --assess --type execute --verbose dist/AUTO.app
```
Expected output: `dist/AUTO.app: accepted, source=Developer ID`.

