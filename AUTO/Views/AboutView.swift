//
//  AboutView.swift
//  AUTO
//
//  Native macOS About AUTO dialog.
//  Presents official mascot branding, version information, system compatibility,
//  open-source acknowledgements, and zero-telemetry policy.
//

import SwiftUI

public struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header with mascot branding
            VStack(spacing: 12) {
                Image(nsImage: BrandAssetManager.shared.mascotImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 88, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(BrandTheme.Gradients.cardBorder, lineWidth: 2)
                    )
                    .shadow(color: BrandTheme.Colors.cyan.opacity(0.4), radius: 16, x: 0, y: 6)
                
                VStack(spacing: 4) {
                    Text(BrandTheme.appName)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(BrandTheme.Gradients.titleGradient)
                    
                    Text(BrandTheme.tagline)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(BrandTheme.Colors.textSecondary)
                    
                    HStack(spacing: 6) {
                        Text("Version \(BrandTheme.version) (Build \(BrandTheme.buildNumber))")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(BrandTheme.Colors.cyan)
                        
                        Text("•")
                            .foregroundColor(BrandTheme.Colors.textTertiary)
                        
                        Text(BrandTheme.compatibility)
                            .font(.system(size: 11))
                            .foregroundColor(BrandTheme.Colors.textTertiary)
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.top, 28)
            .padding(.bottom, 20)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Details & Acknowledgements
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    // Pillars Card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CORE COMMITMENTS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(BrandTheme.Colors.cyan)
                        
                        bulletPoint(icon: "checkmark.seal.fill", title: "100% Free Forever", description: "No subscriptions, no in-app purchases, no paywalls, and no advertisements.")
                        bulletPoint(icon: "lock.shield.fill", title: "Zero Telemetry & Private", description: "Microphone captures are ephemeral. Audio is never cached to disk or tracked.")
                        bulletPoint(icon: "apple.terminal.fill", title: "Native macOS Engineering", description: "Engineered purely in native Swift, SwiftUI, AppKit, AVFoundation, and Speech.")
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(BrandTheme.Colors.surfaceNavy, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
                    
                    // Acknowledgements Card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("INSPIRATION & ACKNOWLEDGEMENTS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(BrandTheme.Colors.purple)
                        
                        bulletPoint(icon: "heart.fill", title: "HeyClicky Reference", description: "Interaction patterns inspired by the open-source HeyClicky project by Farza.")
                        bulletPoint(icon: "sparkles", title: "Google Gemini API", description: "Multimodal visual reasoning powered by Google DeepMind's Gemini models.")
                        bulletPoint(icon: "network", title: "OmniRoute Gateway", description: "Universal model gateway support for local and remote AI deployments.")
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(BrandTheme.Colors.surfaceNavy, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
                }
                .padding(20)
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Footer
            HStack {
                Text("Designed & Built for macOS")
                    .font(.system(size: 11))
                    .foregroundColor(BrandTheme.Colors.textTertiary)
                
                Spacer()
                
                Button("Done") {
                    AboutWindowManager.shared.close()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(BrandTheme.Colors.cyan)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(BrandTheme.Colors.deepNavy)
        }
        .frame(width: 440, height: 490)
        .background(BrandTheme.Colors.deepNavy)
    }
    
    private func bulletPoint(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(BrandTheme.Colors.cyan)
                .frame(width: 16)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(BrandTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

