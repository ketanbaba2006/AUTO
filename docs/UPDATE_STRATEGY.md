# AUTO Future-Ready Update Strategy

## 1. Update Architecture Principles

1. **User Control**: Updates must never download, install, or restart in the background silently. The user maintains explicit control.
2. **Privacy First**: Version checks transmit zero telemetry, device fingerprints, or tracking identifiers.
3. **No Heavy Third-Party Bloat**: AUTO avoids bundling large auto-update frameworks that add bloat or background daemons.
4. **Verified Integrity**: Any update must match verified SHA-256 checksums before installation.

---

## 2. Release Metadata Format

AUTO consumes a lightweight, structured JSON feed hosted alongside releases (`release-metadata.json`):

```json
{
  "version": "1.0.0",
  "buildNumber": "1",
  "releaseDate": "2026-10-31",
  "minimumMacOSVersion": "14.0",
  "downloadURL": "https://github.com/auto-companion/auto/releases/download/v1.0.0/AUTO-1.0.0.dmg",
  "sha256": "66c0af0128de2099d95e53b50dddb6f01aa9de65084fce401ac47aa3057b03ae",
  "releaseNotes": "Official release with complete 7-fragment native architecture.",
  "isCriticalSecurityUpdate": false
}
```

---

## 3. Version Check Workflow (Initial Release)

In **Settings -> About AUTO**:
1. User clicks **"Check for Updates"**.
2. AUTO performs a lightweight HTTPS `GET` request to the release metadata endpoint.
3. Compares semantic version (`1.0.0`) and build number (`1`) against the local `BrandTheme.version`.
4. If a newer version is detected:
   - A notification badge appears in Settings.
   - The release notes are displayed.
   - A **"Download Update"** button opens the verified download URL in the user's default browser.
5. If the application is up-to-date:
   - Displays *"AUTO is up to date (v1.0.0)"*.

---

## 4. Manual Installation Procedure
For the initial release, users perform a standard macOS app replacement:
1. Download the new DMG installer.
2. Mount the DMG and drag `AUTO.app` into `/Applications`.
3. Finder prompts: *"An older item named AUTO already exists in this location. Do you want to replace it?"*
4. Click **Replace**.
5. All local preferences, Keychain secrets, and memories (`agent_memory.json`) are preserved automatically in `~/Library/Application Support/AUTO/`.

