//
//  BrandAssetManager.swift
//  AUTO
//
//  High-performance, cached asset loader and renderer for official AUTO brand assets.
//  Safely resolves Assets.xcassets, bundled resources, and vector fallbacks.
//

import AppKit
import Foundation

public final class BrandAssetManager: @unchecked Sendable {
    public static let shared = BrandAssetManager()
    
    private let lock = NSLock()
    private var cachedLogo: NSImage?
    private var cachedMascot: NSImage?
    private var cachedAppIcon: NSImage?
    private var cachedMenuBarIcon: NSImage?
    
    public init() {}
    
    // MARK: - Official Brand Assets
    
    /// Complete AUTO logo with mascot and wordmark (1024x1024)
    public var logoImage: NSImage {
        lock.lock()
        defer { lock.unlock() }
        if let cached = cachedLogo { return cached }
        
        let loaded = loadResourceImage(named: "auto_logo", catalogName: "AUTOLogo")
            ?? generateFallbackLogo()
        cachedLogo = loaded
        return loaded
    }
    
    /// Focused AUTO mascot portrait artwork (1024x1024)
    public var mascotImage: NSImage {
        lock.lock()
        defer { lock.unlock() }
        if let cached = cachedMascot { return cached }
        
        let loaded = loadResourceImage(named: "auto_mascot", catalogName: "AUTOMascot")
            ?? generateFallbackMascot()
        cachedMascot = loaded
        return loaded
    }
    
    /// macOS App Icon (square squircle tile)
    public var appIconImage: NSImage {
        lock.lock()
        defer { lock.unlock() }
        if let cached = cachedAppIcon { return cached }
        
        let loaded = loadResourceImage(named: "auto_app_icon", catalogName: "AUTOAppIcon")
            ?? logoImage
        cachedAppIcon = loaded
        return loaded
    }
    
    /// Crisp, vector-rendered mascot silhouette for macOS menu bar (18x18 or 20x20)
    public func menuBarMascotIcon(size: CGFloat = 18.0) -> NSImage {
        lock.lock()
        if let cached = cachedMenuBarIcon, cached.size.width == size {
            lock.unlock()
            return cached
        }
        lock.unlock()
        
        let img = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let w = rect.width
            let h = rect.height
            
            // Outer robot head squircle (smooth rounded rect)
            let headRect = NSRect(x: w * 0.18, y: h * 0.16, width: w * 0.64, height: h * 0.62)
            let headPath = NSBezierPath(roundedRect: headRect, xRadius: w * 0.22, yRadius: h * 0.22)
            
            // Crest/fin pointing up from top of head
            let crestPath = NSBezierPath()
            crestPath.move(to: NSPoint(x: w * 0.44, y: h * 0.74))
            crestPath.curve(
                to: NSPoint(x: w * 0.58, y: h * 0.96),
                controlPoint1: NSPoint(x: w * 0.46, y: h * 0.88),
                controlPoint2: NSPoint(x: w * 0.52, y: h * 0.96)
            )
            crestPath.curve(
                to: NSPoint(x: w * 0.68, y: h * 0.74),
                controlPoint1: NSPoint(x: w * 0.64, y: h * 0.90),
                controlPoint2: NSPoint(x: w * 0.66, y: h * 0.80)
            )
            crestPath.close()
            
            // Left headphone cup
            let leftEar = NSRect(x: w * 0.05, y: h * 0.28, width: w * 0.16, height: h * 0.38)
            let leftEarPath = NSBezierPath(roundedRect: leftEar, xRadius: w * 0.08, yRadius: h * 0.08)
            
            // Right headphone cup
            let rightEar = NSRect(x: w * 0.79, y: h * 0.28, width: w * 0.16, height: h * 0.38)
            let rightEarPath = NSBezierPath(roundedRect: rightEar, xRadius: w * 0.08, yRadius: h * 0.08)
            
            // Inner visor cutout
            let visorRect = NSRect(x: w * 0.26, y: h * 0.26, width: w * 0.48, height: h * 0.42)
            let visorPath = NSBezierPath(roundedRect: visorRect, xRadius: w * 0.14, yRadius: h * 0.14)
            
            // Draw main body (head + crest + ears)
            NSColor.black.setFill()
            headPath.fill()
            crestPath.fill()
            leftEarPath.fill()
            rightEarPath.fill()
            
            // Cut out visor in center
            NSGraphicsContext.current?.compositingOperation = .destinationOut
            visorPath.fill()
            
            // Draw smiling eyes (curved smiling arcs ^^) inside visor
            NSGraphicsContext.current?.compositingOperation = .sourceOver
            NSColor.black.setStroke()
            
            let eyeY = h * 0.44
            let eyeW = w * 0.12
            let eyeH = h * 0.10
            
            // Left smiling eye arc
            let leftEye = NSBezierPath()
            leftEye.move(to: NSPoint(x: w * 0.33, y: eyeY))
            leftEye.curve(to: NSPoint(x: w * 0.33 + eyeW, y: eyeY),
                          controlPoint1: NSPoint(x: w * 0.33 + eyeW * 0.25, y: eyeY + eyeH),
                          controlPoint2: NSPoint(x: w * 0.33 + eyeW * 0.75, y: eyeY + eyeH))
            leftEye.lineWidth = w * 0.08
            leftEye.lineCapStyle = .round
            leftEye.stroke()
            
            // Right smiling eye arc
            let rightEye = NSBezierPath()
            rightEye.move(to: NSPoint(x: w * 0.55, y: eyeY))
            rightEye.curve(to: NSPoint(x: w * 0.55 + eyeW, y: eyeY),
                           controlPoint1: NSPoint(x: w * 0.55 + eyeW * 0.25, y: eyeY + eyeH),
                           controlPoint2: NSPoint(x: w * 0.55 + eyeW * 0.75, y: eyeY + eyeH))
            rightEye.lineWidth = w * 0.08
            rightEye.lineCapStyle = .round
            rightEye.stroke()
            
            return true
        }
        
        img.isTemplate = true
        lock.lock()
        cachedMenuBarIcon = img
        lock.unlock()
        return img
    }
    
    // MARK: - Resource Resolution Strategy
    
    private func loadResourceImage(named baseName: String, catalogName: String) -> NSImage? {
        // 1. Try Assets.xcassets named asset
        if let asset = NSImage(named: NSImage.Name(catalogName)) {
            return asset
        }
        
        // 2. Try Bundle.module resource URL (SwiftPM resource bundle)
        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(forResource: baseName, withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            return img
        }
        #endif
        
        // 3. Try main bundle resources
        if let url = Bundle.main.url(forResource: baseName, withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            return img
        }
        
        // 4. Try current working directory Resources fallback
        let localPath = "AUTO/Resources/\(baseName).png"
        if FileManager.default.fileExists(atPath: localPath),
           let img = NSImage(contentsOfFile: localPath) {
            return img
        }
        
        // 5. Try root Assets.xcassets image path
        let isetPath = "Assets.xcassets/\(catalogName).imageset/\(catalogName)_1024.png"
        if FileManager.default.fileExists(atPath: isetPath),
           let img = NSImage(contentsOfFile: isetPath) {
            return img
        }
        
        return nil
    }
    
    // MARK: - Programmatic Fallbacks
    
    private func generateFallbackLogo() -> NSImage {
        let size = NSSize(width: 512, height: 512)
        return NSImage(size: size, flipped: false) { rect in
            BrandTheme.Colors.nsDeepNavy.setFill()
            rect.fill()
            
            let title = "AUTO"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 72, weight: .bold),
                .foregroundColor: BrandTheme.Colors.nsCyan
            ]
            let str = NSAttributedString(string: title, attributes: attrs)
            let strSize = str.size()
            let origin = NSPoint(x: (rect.width - strSize.width) / 2.0, y: (rect.height - strSize.height) / 2.0)
            str.draw(at: origin)
            return true
        }
    }
    
    private func generateFallbackMascot() -> NSImage {
        return menuBarMascotIcon(size: 256.0)
    }
}

