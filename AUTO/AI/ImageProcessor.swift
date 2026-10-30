//
//  ImageProcessor.swift
//  AUTO
//
//  Prepares, scales, downsamples, and compresses screen captures for multimodal AI inference.
//  Preserves visual legibility while reducing network payload and latency.
//

import AppKit
import Foundation
import CryptoKit

public final class ImageProcessor: @unchecked Sendable {
    public static let shared = ImageProcessor()
    
    private let maxDimension: CGFloat = 1536.0
    private let jpegCompressionQuality: CGFloat = 0.75
    
    // In-memory cache for recent image hash to prevent duplicate compression
    private let cacheLock = NSLock()
    private var lastImageHash: String?
    private var lastCompressedBase64: String?
    
    public init() {}
    
    /// Processes raw image data (PNG or TIFF from screen capture) and returns an optimized Base64 JPEG string.
    public func processScreenshot(data: Data) throws -> String {
        guard !data.isEmpty else {
            throw AUTOError.parsingError(detail: "Screenshot data is empty.")
        }
        
        // Fast hash check
        let hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        cacheLock.lock()
        if lastImageHash == hash, let cached = lastCompressedBase64 {
            cacheLock.unlock()
            AppLogger.shared.debug("ImageProcessor: Reusing cached compressed screenshot.", category: .screen)
            return cached
        }
        cacheLock.unlock()
        
        guard let nsImage = NSImage(data: data) else {
            throw AUTOError.parsingError(detail: "Unable to decode screenshot data into NSImage.")
        }
        
        let resizedData = try resizeAndCompress(image: nsImage)
        let base64String = resizedData.base64EncodedString()
        
        cacheLock.lock()
        self.lastImageHash = hash
        self.lastCompressedBase64 = base64String
        cacheLock.unlock()
        
        AppLogger.shared.debug("ImageProcessor: Compressed screenshot from \(data.count) bytes to \(resizedData.count) bytes.", category: .screen)
        return base64String
    }
    
    /// Resizes NSImage if its dimensions exceed maxDimension, and encodes it as JPEG.
    public func resizeAndCompress(image: NSImage) throws -> Data {
        let originalSize = image.size
        guard originalSize.width > 0, originalSize.height > 0 else {
            throw AUTOError.parsingError(detail: "Invalid image dimensions.")
        }
        
        var targetSize = originalSize
        let maxSide = max(originalSize.width, originalSize.height)
        if maxSide > maxDimension {
            let scale = maxDimension / maxSide
            targetSize = NSSize(width: originalSize.width * scale, height: originalSize.height * scale)
        }
        
        // Render into target size bitmap representation
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(targetSize.width),
            pixelsHigh: Int(targetSize.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            throw AUTOError.parsingError(detail: "Failed to allocate bitmap image representation.")
        }
        
        rep.size = targetSize
        NSGraphicsContext.saveGraphicsState()
        let context = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current = context
        
        context?.imageInterpolation = .high
        image.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: originalSize),
            operation: .copy,
            fraction: 1.0
        )
        
        NSGraphicsContext.restoreGraphicsState()
        
        guard let jpegData = rep.representation(using: .jpeg, properties: [.compressionFactor: jpegCompressionQuality]) else {
            throw AUTOError.parsingError(detail: "Failed to generate JPEG representation.")
        }
        
        return jpegData
    }
    
    public func clearCache() {
        cacheLock.lock()
        lastImageHash = nil
        lastCompressedBase64 = nil
        cacheLock.unlock()
    }
}

