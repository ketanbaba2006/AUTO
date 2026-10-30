# AUTO Apple Notarization Guide

## 1. Overview

Notarization is Apple's automated malware analysis service. When an app is signed with an Apple Developer ID and notarized, Gatekeeper allows users to double-click and run the application without any security override warnings.

---

## 2. Prerequisites
1. An active Apple Developer Program account (\$99/year).
2. A **Developer ID Application** signing certificate installed in your macOS Keychain.
3. An App Store Connect API Key or an App-Specific Password for `notarytool`.

---

## 3. Configuring Notarytool Credentials

Store your App Store Connect credentials securely in your local Keychain:

```bash
xcrun notarytool store-credentials "AC_NOTARY" \
  --apple-id "developer@example.com" \
  --team-id "TEAMID1234" \
  --password "abcd-efgh-ijkl-mnop"
```

---

## 4. Submitting the DMG for Notarization

Once you have generated the signed `AUTO-1.0.0.dmg` using Developer ID:

```bash
xcrun notarytool submit dist/AUTO-1.0.0.dmg \
  --keychain-profile "AC_NOTARY" \
  --wait
```

### Checking Submission Status:
If not waiting synchronously:
```bash
xcrun notarytool log <submission-id> --keychain-profile "AC_NOTARY"
```

---

## 5. Stapling the Notarization Ticket

Once Apple confirms approval (`status: Accepted`), staple the ticket to the disk image:

```bash
xcrun stapler staple dist/AUTO-1.0.0.dmg
```

Verify the staple:
```bash
spctl --assess --type open --context context:primary-signature --verbose dist/AUTO-1.0.0.dmg
```
Expected output: `dist/AUTO-1.0.0.dmg: accepted, source=Notarized Developer ID`.

The DMG is now ready for zero-friction distribution on any Mac!

