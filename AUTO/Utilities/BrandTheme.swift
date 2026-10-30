//
//  BrandTheme.swift
//  AUTO
//
//  Official brand identity, design tokens, colors, and gradients for AUTO.
//  Application: AUTO - Your Personal AI Desktop Companion
//

import AppKit
import SwiftUI

public enum BrandTheme {
    public static let appName = "AUTO"
    public static let tagline = "Your Personal AI Desktop Companion."
    public static let version = "1.0.0"
    public static let buildNumber = "1"
    public static let compatibility = "macOS 14.0 Sonoma or later"
    public static let bundleIdentifier = "com.auto.desktop.companion"
    
    // MARK: - Official Brand Palette
    public enum Colors {
        /// Primary Electric Cyan: Glowing eyes, listening state, active triggers
        public static let cyan = Color(red: 0.0, green: 0.85, blue: 1.0)
        public static let nsCyan = NSColor(red: 0.0, green: 0.85, blue: 1.0, alpha: 1.0)
        
        /// Vibrant Electric Blue: Headphones, accents, secondary actions
        public static let electricBlue = Color(red: 0.10, green: 0.60, blue: 1.0)
        public static let nsElectricBlue = NSColor(red: 0.10, green: 0.60, blue: 1.0, alpha: 1.0)
        
        /// Neon Purple: Accent, thinking state, OmniRoute highlight
        public static let purple = Color(red: 0.65, green: 0.28, blue: 0.98)
        public static let nsPurple = NSColor(red: 0.65, green: 0.28, blue: 0.98, alpha: 1.0)
        
        /// Deep Navy: Mascot background and main panel backdrop
        public static let deepNavy = Color(red: 0.035, green: 0.047, blue: 0.075)
        public static let nsDeepNavy = NSColor(red: 0.035, green: 0.047, blue: 0.075, alpha: 1.0)
        
        /// Surface Card Navy: Content cards and grouped controls
        public static let surfaceNavy = Color(red: 0.07, green: 0.085, blue: 0.13)
        public static let nsSurfaceNavy = NSColor(red: 0.07, green: 0.085, blue: 0.13, alpha: 1.0)
        
        /// Elevated Glass Navy: Popovers, floating badges
        public static let elevatedNavy = Color(red: 0.11, green: 0.13, blue: 0.18)
        
        /// High contrast foreground
        public static let foreground = Color.white
        public static let textSecondary = Color.white.opacity(0.65)
        public static let textTertiary = Color.white.opacity(0.40)
    }
    
    // MARK: - Gradients
    public enum Gradients {
        /// Official brand title gradient (Cyan -> Purple)
        public static let titleGradient = LinearGradient(
            colors: [Colors.cyan, Colors.purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        /// Companion panel backdrop gradient
        public static let panelBackdrop = LinearGradient(
            colors: [
                Color(red: 0.09, green: 0.11, blue: 0.16).opacity(0.97),
                Color(red: 0.05, green: 0.06, blue: 0.09).opacity(0.98)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        
        /// Thinking aura gradient
        public static let thinkingAura = AngularGradient(
            gradient: Gradient(colors: [Colors.cyan, Colors.purple, Colors.electricBlue, Colors.cyan]),
            center: .center
        )
        
        /// Card glass border gradient
        public static let cardBorder = LinearGradient(
            colors: [Colors.cyan.opacity(0.35), Colors.purple.opacity(0.20), Color.white.opacity(0.08)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

