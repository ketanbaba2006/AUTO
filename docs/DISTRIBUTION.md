# AUTO Release Distribution Architecture

## 1. Distribution Strategy Overview

AUTO is distributed as a standalone, self-contained native macOS desktop companion. It requires no installers that tamper with system directories or install kernel extensions.

```
┌────────────────────────────────────────────────────────┐
│                   DISTRIBUTION FLOW                    │
└────────────────────────────────────────────────────────┘
                           │
       Developer compiles Release with SPM:
       `swift build -c release`
                           ▼
       Assembly of native `AUTO.app` bundle:
       - Info.plist, AppIcon.icns, hardened entitlements
                           ▼
       Ad-hoc code signing:
       `codesign --force --deep --sign - AUTO.app`
                           ▼
       DMG generation using macOS hdiutil:
       - UDZO compression with /Applications symlink
       - Output: `dist/AUTO-1.0.0.dmg` (11 MB)
                           ▼
       Real SHA-256 verification and website metadata sync:
       `66c0af0128de2099d95e53b50dddb6f01aa9de65084fce401ac47aa3057b03ae`
```

---

## 2. Release Artifacts

| Artifact | Path | Size | Description |
| :--- | :--- | :--- | :--- |
| **macOS App Bundle** | `dist/AUTO.app` | **16 MB** | Standalone native application containing binary, resources, entitlements, and metadata. |
| **Disk Image Installer** | `dist/AUTO-1.0.0.dmg` | **11 MB** | Mountable read-only disk image with standard drag-and-drop installer workflow. |

---

## 3. Distribution Channels

### 1. Direct Website Download Portal
- Hosted via the official AUTO website (`/download`).
- Displays real verified release metadata (version, build, file size, SHA-256 checksum).
- Direct download button pointing to `dist/AUTO-1.0.0.dmg`.

### 2. GitHub Releases
- GitHub Releases will host tagged versions (e.g. `v1.0.0`).
- Release assets include `AUTO-1.0.0.dmg` alongside the full changelog and release notes.

### 3. Homebrew Cask (Future Roadmap)
- A community Cask formula can distribute AUTO directly via:
  ```bash
  brew install --cask auto
  ```
  pointing to the official GitHub release DMG.

