# AUTO Brand & Visual Identity Guidelines

## 1. Executive Summary & Brand Identity

**Application Name**: AUTO  
**Tagline**: Your Personal AI Desktop Companion  
**Platform**: macOS (14.0 Sonoma or later)  
**Product Policy**: 100% Free Forever — No subscriptions, no ads, no telemetry, no paywalls.

AUTO is an independent native macOS AI desktop companion inspired by the open-source HeyClicky architecture. The official brand identity is centered around a friendly, futuristic AI robot mascot with glowing cyan-blue eyes, curved smiling arcs, sleek round headphones, a crest fin, and an illuminated blue-and-purple palette set against a deep navy background.

---

## 2. Official Brand Palette

| Token | Name | Hex Code | RGB | SwiftUI / NSColor Role |
|---|---|---|---|---|
| **Primary Cyan** | Electric Cyan | `#00D9FF` | `(0, 217, 255)` | Mascot eyes, listening aura, active hotkey highlights, primary buttons |
| **Electric Blue** | Orbit Blue | `#1A99FF` | `(26, 153, 255)` | Headphone glows, transcribing state, secondary interactive accents |
| **Neon Purple** | Quantum Purple | `#A647FA` | `(166, 71, 250)` | Thinking state aura, reasoning badge, title gradient endpoint |
| **Deep Navy** | Deep Space Navy | `#090C13` | `(9, 12, 19)` | Main companion panel backdrop, mascot canvas, About dialog background |
| **Surface Navy** | Card Surface Navy | `#121621` | `(18, 22, 33)` | Grouped control cards, setting rows, conversation bubbles |
| **Foreground** | High-Contrast White | `#FFFFFF` | `(255, 255, 255)` | Primary titles, readable typography, high-contrast labels |

---

## 3. Asset Catalog & Resource Architecture

AUTO organizes its assets according to Apple Human Interface Guidelines:

```
Assets.xcassets/
├── Contents.json
├── AUTOAppIcon.appiconset/
│   ├── Contents.json
│   ├── icon_16x16.png (16x16)
│   ├── icon_16x16@2x.png (32x32)
│   ├── icon_32x32.png (32x32)
│   ├── icon_32x32@2x.png (64x64)
│   ├── icon_128x128.png (128x128)
│   ├── icon_128x128@2x.png (256x256)
│   ├── icon_256x256.png (256x256)
│   ├── icon_256x256@2x.png (512x512)
│   ├── icon_512x512.png (512x512)
│   └── icon_512x512@2x.png (1024x1024)
├── AUTOLogo.imageset/
│   ├── Contents.json
│   ├── AUTOLogo_256.png (256x256)
│   ├── AUTOLogo_512.png (512x512)
│   └── AUTOLogo_1024.png (1024x1024)
└── AUTOMascot.imageset/
    ├── Contents.json
    ├── AUTOMascot_256.png (256x256)
    ├── AUTOMascot_512.png (512x512)
    └── AUTOMascot_1024.png (1024x1024)
```

In addition to `Assets.xcassets`, standalone assets are compiled into the SwiftPM resource bundle (`AUTO/Resources/`):
- `AUTO.icns`: Native Apple multi-resolution icon file compiled via `iconutil -c icns`.
- `auto_app_icon.png`, `auto_logo.png`, `auto_mascot.png`: Direct PNG fallback representations.

---

## 4. macOS Application Icon & Dock Integration

1. **Multi-Resolution Apple Icon (`AUTO.icns`)**:
   - For smaller sizes (16px, 32px, 64px), the mascot portrait is prominently featured to ensure high legibility and instant recognition in Finder lists and menu bars.
   - For larger sizes (128px to 1024px), the complete squircle icon with ambient glow and the "AUTO" wordmark is rendered at crisp Retina quality.
2. **Runtime Dock Tile Configuration**:
   - In `AppDelegate.applicationDidFinishLaunching`, AUTO sets `NSApplication.shared.applicationIconImage = BrandAssetManager.shared.appIconImage`.
   - This ensures that whether AUTO is launched via Xcode, Terminal (`./.build/debug/AUTO`), or installed as an `.app` bundle, the macOS Dock and application switcher (`Cmd + Tab`) display the official mascot icon immediately.

---

## 5. Menu Bar Branding

At 18x18 or 22x22 points in the macOS menu bar, photographic or complex 3D illustrations lose fidelity. AUTO implements a dedicated vector silhouette in `BrandAssetManager.menuBarMascotIcon(size: 18.0)`:

- **Features**:
  - Smooth robot head squircle with proportional corner radius.
  - Distinctive shark-fin crest emerging from the top of the head.
  - Symmetrical headphone ear cups on left and right.
  - Inner visor cutout with two smiling curved eye arcs (`^ ^`).
- **Template Rendering**:
  - Configured with `isTemplate = true`.
  - Automatically adapts to Light Mode (dark silhouette) and Dark Mode (crisp white silhouette) with native macOS menu bar translucency.
- **Context Menu Interaction**:
  - Left click: Toggles the floating companion panel.
  - Right click: Presents a native context menu with options:
    - *About AUTO...* (Opens native About dialog)
    - *Toggle Companion Panel*
    - *Settings...*
    - *Quit AUTO*

---

## 6. Companion Panel & Dynamic Mascot States

The companion panel features `AUTOMascotView`, rendering the official mascot with live visual feedback tied directly to the state machine (`VoiceState`):

| Voice State | Visual Mascot Representation | Dynamic Aura & Animations |
|---|---|---|
| **IDLE** | Friendly relaxed mascot | Gentle breathing radial cyan glow (2.2s cycle) |
| **LISTENING** | Audio-reactive cyan eye illumination | Concentric acoustic shockwaves expanding with microphone volume (`powerLevel`) |
| **TRANSCRIBING** | Electric blue processing aura | Shimmering border glow indicating speech transcription |
| **THINKING** | Purple & cyan cognitive halo | Smooth rotating angular gradient indicating active AI reasoning |
| **SPEAKING** | Acoustic voice ripple waves | Synchronized green/cyan pulses emitting during text-to-speech output |
| **INTERRUPTED** | Crisp amber warning flash | Indicates user has halted the assistant turn mid-sentence |
| **FAILED** | Subtle alert badge | Soft red alert ring with corner exclamation badge preserving mascot identity |

---

## 7. Onboarding, Settings & About Window

1. **Onboarding Screen (`OnboardingView`)**:
   - Displays a prominent 76x76 hero mascot badge with glowing cyan-purple border.
   - Branded title with electric cyan-to-purple gradient.
   - Deep navy background with subtle contrast cards.
2. **Conversation Empty State (`ConversationView`)**:
   - Displays the mascot alongside interactive prompt suggestions ("What's on my screen right now?", "Help me find the right button to click").
3. **Settings Header (`SettingsView`)**:
   - Integrated mascot icon, "AUTO Settings", and version pill in the navigation bar.
   - Dedicated **About** tab.
4. **Native About AUTO Window (`AboutView` & `AboutWindowManager`)**:
   - Features 88x88 official mascot artwork with ambient back-glow.
   - Displays version `1.0.0 (Build 1)` and system compatibility (`macOS 14.0 Sonoma or later`).
   - Summarizes core commitments (100% Free Forever, Zero Telemetry, Native Swift Architecture).
   - Acknowledges open-source inspirations: HeyClicky and Google Gemini.

---

## 8. Resource Optimization & In-Memory Caching

- `BrandAssetManager` acts as a thread-safe singleton managing asset resolution.
- Decoded `NSImage` instances are cached in memory so images are never repeatedly decompressed from disk during render loops.
- Fallback vector drawing guarantees that the companion panel and menu bar never fail to render, even in stripped headless test environments.

