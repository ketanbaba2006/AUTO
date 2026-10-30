# Contributing to AUTO

Thank you for your interest in contributing to **AUTO — Your Personal AI Desktop Companion**!

AUTO is a 100% native macOS application engineered strictly with Swift, SwiftUI, AppKit, ScreenCaptureKit, CoreGraphics, and Apple Speech.

---

## Code of Conduct & Product Principles

1. **Native macOS Only**: We do not use React, Electron, Flutter, or WebViews for desktop interfaces. Contributions must adhere to native Swift/AppKit engineering.
2. **100% Free Application**: No subscriptions, paywalls, premium tiers, accounts, or telemetry may ever be introduced.
3. **Defense-in-Depth Privacy**:
   - Microphone and screen captures must remain strictly ephemeral (held in RAM only during active inference and immediately destroyed).
   - API keys must always be stored in the macOS Keychain (`KeychainManager`).
   - Consequential or high-risk actions must remain gated behind explicit user confirmation modals.
   - Emergency Stop mechanisms must execute locally in under 10 milliseconds.

---

## Development Setup

### Prerequisites
- Mac running macOS 14.0 (Sonoma) or later.
- Xcode 15.0+ or Apple Command Line Tools (`xcode-select --install`).
- Swift 5.9+ / Swift 6.

### Building and Testing
From the project root:
```bash
# 1. Compile debug binary
swift build

# 2. Run the full automated test suite (84 tests)
./.build/debug/AUTO --test

# 3. Test release compilation and DMG packaging
./scripts/package_app.sh
```

---

## Coding Guidelines

- **Swift Concurrency**: Mark UI-isolated and main-thread classes with `@MainActor`. Ensure actors and async tasks respect cancellation tokens.
- **Documentation Integrity**: Preserve existing docstrings and comments. Update relevant Markdown documentation in `docs/` when altering subsystems.
- **Zero Warnings**: Code must compile with zero genuine compiler warnings.
- **Unit Testing**: Any new tool, action, or provider logic must be paired with unit tests added to `AUTOTestSuite.swift`.

---

## Pull Request Process

1. Fork the repository and create your feature branch from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
2. Verify that all 84 automated tests pass cleanly:
   ```bash
   swift run AUTO --test
   ```
3. Commit with concise, descriptive commit messages.
4. Ensure no secrets, `.env` files, or API credentials are committed.
5. Submit your Pull Request against the `main` branch with a clear summary of changes and testing steps.

