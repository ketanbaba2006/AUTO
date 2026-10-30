# AUTO Pre-Release Quality Verification Checklist

Use this checklist before publishing any official release of AUTO.

---

## 1. Codebase & Compiler Verification
- [ ] Working tree is clean: `git status --porcelain` shows no unexpected edits.
- [ ] No hardcoded API keys, test secrets, or credentials exist in source code (`grep -rnE "AIza|sk-" AUTO/`).
- [ ] Debug build succeeds with 0 errors: `swift build`.
- [ ] Release build succeeds with 0 errors: `swift build -c release`.
- [ ] No compiler warnings in release mode.

---

## 2. Automated Test Suite
- [ ] All automated unit and integration tests pass cleanly:
  ```bash
  ./.build/debug/AUTO --test
  ```
  Expected output: **84 / 84 tests passing (100% success rate)**.

---

## 3. Subsystem Integration Verification
- [ ] **AI Engine**: Gemini API streaming, model discovery, and 403/429 error mapping tested.
- [ ] **Hybrid Engine**: 13 local engine services and Zero-Screenshot privacy gating verified.
- [ ] **Voice**: Hold-Control push-to-talk triggers audio capture and waveform animation; speech interruption immediately silences TTS.
- [ ] **Screen Intelligence**: ScreenCaptureKit captures display/window buffers; ephemeral RAM-only guarantee verified.
- [ ] **Automation**: Accessibility element discovery matches targets; three-tier safety gating displays confirmation modal for high-risk actions.
- [ ] **Emergency Stop**: Voice "Stop", UI red button, and Escape key halt automation in under 10 milliseconds.
- [ ] **Memory**: Persistent memory reads/writes to `agent_memory.json`; sensitive credential scanner rejects passwords and API keys.
- [ ] **Privacy Hub**: Granular chat, memory, and task history clearance works as expected.

---

## 4. Packaging & Distribution Artifacts
- [ ] Execute master packaging script:
  ```bash
  ./scripts/package_app.sh
  ```
- [ ] Verify `dist/AUTO.app` bundle structure:
  - `dist/AUTO.app/Contents/MacOS/AUTO` (executable binary)
  - `dist/AUTO.app/Contents/Info.plist` (valid bundle identifier `com.auto.desktop.companion`)
  - `dist/AUTO.app/Contents/PkgInfo` (APPL????)
  - `dist/AUTO.app/Contents/Resources/AppIcon.icns`
  - `dist/AUTO.app/Contents/Resources/AUTO_AUTO.bundle`
- [ ] Verify code signature: `codesign -v dist/AUTO.app`.
- [ ] Verify `dist/AUTO-1.0.0.dmg` mounts cleanly and displays `/Applications` drag-and-drop shortcut.
- [ ] Compute real SHA-256 checksum: `shasum -a 256 dist/AUTO-1.0.0.dmg`.
- [ ] Update `website/src/release-metadata.json` with the exact verified checksum and file sizes.

---

## 5. Website Verification
- [ ] Website builds cleanly with 0 errors: `cd website && npm run build`.
- [ ] All routes work (`/`, `/features`, `/download`, `/privacy`, `/documentation`, `/about`, `/changelog`).
- [ ] Download button connects to the verified release artifact.
- [ ] Responsive layout renders cleanly on desktop and mobile viewports.

