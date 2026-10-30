# AUTO: Multi-Display Support Architecture

This document describes how **AUTO** handles multi-monitor desktop environments on macOS, including arbitrary display arrangements, negative coordinate spaces, Retina backing scale factors, dynamic display reconfiguration, and ScreenCaptureKit display targeting.

---

## 1. Multi-Monitor Coordinate Systems on macOS

macOS supports complex multi-display arrangements where displays can be placed to the left, right, above, or below one another.

### Primary Display Origin
- The **primary display** (the display containing the macOS menu bar) is anchored at `(x: 0, y: 0)`.
- Displays positioned to the **left** of the primary display have **negative X coordinates** (e.g., `x = -1920` for a 1080p display to the left).
- Displays positioned **above** the primary display in standard AppKit coordinates have **positive Y coordinates**, but in CoreGraphics coordinates (which measure down from the top-left of the primary display), displays above have **negative Y coordinates**.

### Virtual Desktop Coordinate Frame
```
┌───────────────────────────┐  ┌───────────────────────────┐
│ Secondary Display (Left)  │  │ Primary Display (Main)    │
│ Origin: (-1920, 0)        │  │ Origin: (0, 0)            │
│ Size: 1920 x 1080         │  │ Size: 3456 x 2234 (Retina)│
└───────────────────────────┘  └───────────────────────────┘
```

---

## 2. DisplayManager Architecture

AUTO implements `DisplayManager` (`AUTO/Screen/DisplayManager.swift`) as an `@Observable` thread-safe coordinator for all connected displays.

### Key Responsibilities
1. **Display Discovery**: Uses `NSScreen.screens` and `CGGetActiveDisplayList` to enumerate all physical and virtual displays.
2. **Display Info Modeling**:
   - `displayID: CGDirectDisplayID`
   - `name: String` (localized display name)
   - `frame: CGRect` (global desktop coordinates in points)
   - `visibleFrame: CGRect` (excluding Dock and Menu Bar)
   - `scaleFactor: CGFloat` (Retina scaling factor, e.g. 2.0x)
   - `isPrimary: Bool` (true if origin is `(0, 0)`)
3. **Active Display Detection**:
   - Identifies which display currently contains the mouse cursor or the frontmost active application window.
4. **Dynamic Configuration Listening**:
   - Observes `NSApplication.didChangeScreenParametersNotification`.
   - Re-queries connected displays and updates state automatically when monitors are plugged in, unplugged, or rearranged.

---

## 3. Coordinate Transformations

To support AI visual reasoning (where Gemini generates normalized coordinates `[0, 1000]` or `[0.0, 1.0]` relative to a captured screenshot), AUTO performs precise bi-directional coordinate mapping:

### 1. Normalized to Global Desktop Coordinates
```swift
func normalizedToGlobal(point: CGPoint, on displayID: CGDirectDisplayID) -> CGPoint {
    guard let display = displays.first(where: { $0.id == displayID }) else {
        return point
    }
    let globalX = display.frame.origin.x + (point.x * display.frame.width)
    let globalY = display.frame.origin.y + (point.y * display.frame.height)
    return CGPoint(x: globalX, y: globalY)
}
```

### 2. Global Desktop Coordinates to Normalized
```swift
func globalToNormalized(point: CGPoint, on displayID: CGDirectDisplayID) -> CGPoint? {
    guard let display = displays.first(where: { $0.id == displayID }),
          display.frame.contains(point) else {
        return nil
    }
    let normX = (point.x - display.frame.origin.x) / display.frame.width
    let normY = (point.y - display.frame.origin.y) / display.frame.height
    return CGPoint(x: normX, y: normY)
}
```

This ensures that even when secondary monitors reside in negative coordinate spaces (e.g. `x = -1920`), normalized coordinates `(0.5, 0.5)` map exactly to the center point `(-960, 540)` of that monitor.

---

## 4. ScreenCaptureKit Multi-Display Targeting

`ScreenCaptureManager` uses Apple's `ScreenCaptureKit` to target individual displays without capturing unwanted monitors:

1. **Shareable Content Query**:
   ```swift
   let shareable = try await SCShareableContent.excludingDesktopWindows(
       false,
       onScreenWindowsOnly: true
   )
   ```
2. **Display Filtering**:
   ```swift
   guard let targetDisplay = shareable.displays.first(where: { $0.displayID == displayID }) else {
       throw ScreenCaptureError.displayNotFound(displayID)
   }
   
   // Exclude AUTO windows to avoid self-capture loops
   let filter = SCContentFilter(display: targetDisplay, excludingWindows: autoWindows)
   ```
3. **Capture Execution**:
   Uses `SCScreenshotManager.captureImage(contentFilter:configuration:)` to capture only the pixels belonging to the specified display.

---

## 5. Retina and High-DPI Handling

- **Logical Points vs Physical Pixels**:
  On a 2x Retina display, a window of size `1728 x 1117` points captures as an image of `3456 x 2234` physical pixels.
- **Downsampling Pipeline**:
  `ScreenshotProcessor` resizes Retina captures down to a configurable maximum dimension (1920, 1536, or 1280 pixels) while strictly preserving aspect ratio.
- **Aspect Ratio Formula**:
  ```swift
  let scale = min(CGFloat(maxDimension) / imageWidth, CGFloat(maxDimension) / imageHeight)
  if scale < 1.0 {
      let targetSize = CGSize(width: imageWidth * scale, height: imageHeight * scale)
      // High-quality CoreGraphics bicubic downsample
  }
  ```

---

## 6. Disconnection and Reconfiguration Safety

When a display is unplugged:
- `NSApplication.didChangeScreenParametersNotification` triggers `refreshDisplays()`.
- If the currently selected display is removed, AUTO automatically falls back to the primary display.
- Active screen sharing streams check display validity before each capture cycle; if the target display disappears, sharing transitions to `idle` with an informative error rather than crashing.

