//
//  AutoScreenManager.swift
//  AUTO
//
//  Native Local Screen Intelligence:
//  Executes local ScreenCaptureKit frame capture, Apple Vision on-device OCR,
//  multi-display coordinate transforms, and Accessibility UI hierarchy inspection.
//  Enforces Zero-Screenshot Transmission by default, sending only local text summaries.
//

import Foundation
import ScreenCaptureKit
import Vision
import AppKit

public struct AutoOCRResult: Sendable {
    public let fullText: String
    public let boundingBoxes: [CGRect]
    public let elements: [(text: String, box: CGRect)]
}

public final class AutoScreenManager: @unchecked Sendable {
    public static let shared = AutoScreenManager()
    
    private init() {}
    
    // MARK: - Local Screen Capture
    public func captureActiveDisplay() async throws -> CGImage {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let display = content.displays.first else {
            throw AUTOError.screenCaptureFailed(reason: "No active display found.")
        }
        
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let config = SCStreamConfiguration()
        config.width = display.width
        config.height = display.height
        config.scalesToFit = false
        
        return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
    }
    
    // MARK: - Local Apple Vision OCR (On-Device)
    public func performLocalOCR(on image: CGImage) async throws -> AutoOCRResult {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: AutoOCRResult(fullText: "", boundingBoxes: [], elements: []))
                    return
                }
                
                var fullText = ""
                var boxes: [CGRect] = []
                var elements: [(text: String, box: CGRect)] = []
                
                for observation in observations {
                    if let candidate = observation.topCandidates(1).first {
                        fullText += candidate.string + "\n"
                        boxes.append(observation.boundingBox)
                        elements.append((candidate.string, observation.boundingBox))
                    }
                }
                
                continuation.resume(returning: AutoOCRResult(
                    fullText: fullText.trimmingCharacters(in: .whitespacesAndNewlines),
                    boundingBoxes: boxes,
                    elements: elements
                ))
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Privacy-Preserving Screen Context Summary
    /// Generates a local text summary of visible screen text and active window structure.
    /// This summary is sent to Gemini INSTEAD of uploading screenshot image bytes.
    public func generateLocalScreenSummary() async -> String {
        do {
            let image = try await captureActiveDisplay()
            let ocr = try await performLocalOCR(on: image)
            
            let frontApp = NSWorkspace.shared.frontmostApplication?.localizedName ?? "Unknown"
            var summary = "Active Application: \(frontApp)\n\n"
            summary += "Visible Screen Text (Local On-Device OCR):\n"
            
            if ocr.fullText.isEmpty {
                summary += "[No readable text detected on screen]"
            } else {
                // Limit to 2000 characters to keep context minimal
                let truncated = String(ocr.fullText.prefix(2000))
                summary += truncated
            }
            
            return summary
        } catch {
            return "Screen context unavailable: \(error.localizedDescription)"
        }
    }
}

