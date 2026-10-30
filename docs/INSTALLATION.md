# Installing and Running AUTO

## 1. System Requirements

AUTO is engineered exclusively for macOS.

| Requirement | Minimum Specification | Recommended |
| :--- | :--- | :--- |
| **Operating System** | macOS 14.0 (Sonoma) | macOS 14.4+ or macOS 15.0+ |
| **Architecture** | Apple Silicon or Intel x86_64 | Apple Silicon (M1/M2/M3/M4) |
| **RAM** | 8 GB | 16 GB+ |
| **Disk Space** | 200 MB free space | 500 MB free space |
| **Microphone** | Built-in or USB microphone | Any studio or built-in mic |
| **Display** | Single Retina or standard display | Single or multi-display |

---

## 2. Installation via Disk Image (DMG)

1. Download or build the official disk image: `dist/AUTO-1.0.0.dmg`.
2. Double-click `AUTO-1.0.0.dmg` to mount the disk image.
3. Drag the **AUTO** icon into your **Applications** folder.
4. Eject the disk image.
5. Launch **AUTO** from `/Applications` or via Spotlight (`⌘ Space -> AUTO`).

### Gatekeeper / Ad-Hoc Signing Notice
Because AUTO is an open-source, independent companion built without a paid corporate Apple Developer Certificate, macOS Gatekeeper may prompt:
> *"AUTO cannot be opened because the developer cannot be verified."*

To open on first launch:
1. Right-click (or Control-click) `AUTO.app` in `/Applications`.
2. Select **Open** from the context menu.
3. Click **Open** in the confirmation dialog.
4. You will only need to do this once.

---

## 3. Building From Source

If you prefer to compile AUTO directly from source:

### Prerequisites
- Xcode 15.0+ or Apple Command Line Tools:
```bash
xcode-select --install
swift --version
```

### Build & Run
```bash
# Clone the repository
git clone https://github.com/auto-companion/auto.git
cd auto

# Build in debug mode
swift build

# Run automated offline test suite (84 tests)
./.build/debug/AUTO --test

# Run the app directly
swift run AUTO
```

### Packaging .app and .dmg
To generate the release `.app` bundle and `.dmg` installer:
```bash
./scripts/package_app.sh
```
The output artifacts will be placed in `dist/`:
- `dist/AUTO.app`
- `dist/AUTO-1.0.0.dmg`

---

## 4. First-Launch Setup & Permissions

When you first open AUTO, an interactive 5-step onboarding wizard will guide you through:
1. **Welcome**: Meet your personal companion.
2. **Permissions**: Grant Accessibility, Microphone, Speech Recognition, and Screen Recording access.
3. **AI Configuration**: Enter your Google Gemini API key.
4. **Voice & Screen Interaction**: Learn the Hold-Control push-to-talk workflow.
5. **Memory & Safety**: Learn about local memory storage and Emergency Stop failsafes.

---

## 5. Uninstalling AUTO

To completely remove AUTO from your system:
1. Quit AUTO from the Menu Bar icon (`Right-click mascot -> Quit AUTO`).
2. Move `/Applications/AUTO.app` to Trash.
3. To delete local memory and settings:
```bash
rm -rf ~/Library/Application\ Support/AUTO
defaults delete com.auto.desktop.companion
```
4. To remove stored API keys from Keychain:
   Open **Keychain Access.app** and delete `gemini_api_key`.

