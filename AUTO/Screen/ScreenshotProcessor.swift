//
//  ScreenshotProcessor.swift
//  AUTO
//
//  High-performance image processing service for ScreenCaptureKit captures.
//  Resizes high-resolution Retina screenshots, maintains aspect ratio, strips metadata,
//  and produces legibility-optimized JPEG and Base64 payloads for multimodal AI models.
//

import AppKit
import CoreGraphics
import CryptoKit
import Foundation

public struct ProcessedScreenshot: Sendable {
    public let jpegData: Data
    public let base64String: String
    public let originalPixelSize: CGSize
    public let targetPixelSize: CGSize
    public let originalByteCount: Int
    public let compressedByteCount: Int
    public let compressionRatio: Double
    public let sha256Hash: String
}

public final class ScreenshotProcessor: @unchecked Sendable {
    public static let shared = ScreenshotProcessor()
    
    private let cacheLock = NSLock()
    private var lastHash: String?
    private var lastResult: ProcessedScreenshot?
    
    public init() {}
    
    /// Processes a CGImage into an optimized JPEG payload and Base64 string.
    public func process(
        cgImage: CGImage,
        maxDimension: Int = 1920,
        compressionQuality: Double = 0.80
    ) throws -> ProcessedScreenshot {
        let originalWidth = cgImage.width
        let originalHeight = cgImage.height
        
        guard originalWidth > 0 && originalHeight > 0 else {
            throw AUTOError.screenCaptureError(reason: "Invalid CGImage dimensions (\(originalWidth)x\(originalHeight)).")
        }
        
        let maxSide = max(originalWidth, originalHeight)
        let scaleFactor = (maxSide > maxDimension) ? Double(maxDimension) / Double(maxSide) : 1.0
        
        let targetWidth = Int(Double(originalWidth) * scaleFactor)
        let targetHeight = Int(Double(originalHeight) * scaleFactor)
        
        // Fast path: if dimensions are within bounds, convert directly to NSBitmapImageRep
        let bitmapRep: NSBitmapImageRep
        if scaleFactor == 1.0 {
            bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        } else {
            // Allocate downsampled bitmap
            guard let resizedContext = CGContext(
                data: nil,
                width: targetWidth,
                height: targetHeight,
                bitsPerComponent: 8,
                bytesPerRow: targetWidth * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                throw AUTOError.screenCaptureError(reason: "Failed to allocate CGContext for screenshot downsampling.")
            }
            
            resizedContext.interpolationQuality = .high
            resizedContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight))
            
            guard let resizedCGImage = resizedContext.makeImage() else {
                throw AUTOError.screenCaptureError(reason: "Failed to create downsampled CGImage from context.")
            }
            bitmapRep = NSBitmapImageRep(cgImage: resizedCGImage)
        }
        
        // Encode to JPEG representation with optimal legibility compression factor
        let compressionNumber = NSNumber(value: min(max(compressionQuality, 0.4), 1.0))
        guard let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: compressionNumber]) else {
            throw AUTOError.screenCaptureError(reason: "Failed to encode screenshot bitmap into JPEG representation.")
        }
        
        // Calculate SHA-256 hash for cache verification
        let hash = SHA256.hash(data: jpegData).map { String(format: "%02x", $0) }.joined()
        
        cacheLock.lock()
        if lastHash == hash, let cached = lastResult {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()
        
        let base64String = jpegData.base64EncodedString()
        let originalEstBytes = originalWidth * originalHeight * 4
        let ratio = originalEstBytes > 0 ? Double(jpegData.count) / Double(originalEstBytes) : 1.0
        
        let result = ProcessedScreenshot(
            jpegData: jpegData,
            base64String: base64String,
            originalPixelSize: CGSize(width: originalWidth, height: originalHeight),
            targetPixelSize: CGSize(width: targetWidth, height: targetHeight),
            originalByteCount: originalEstBytes,
            compressedByteCount: jpegData.count,
            compressionRatio: ratio,
            sha256Hash: hash
        )
        
        cacheLock.lock()
        self.lastHash = hash
        self.lastResult = result
        cacheLock.unlock()
        
        AppLogger.shared.debug("ScreenshotProcessor: Processed \(originalWidth)x\(originalHeight) -> \(targetWidth)x\(targetHeight) (\(jpegData.count) bytes)", category: .screen)
        return result
    }
    
    /// Processes raw image data (PNG, TIFF, JPEG).
    public func process(
        data: Data,
        maxDimension: Int = 1920,
        compressionQuality: Double = 0.80
    ) throws -> ProcessedScreenshot {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw AUTOError.screenCaptureError(reason: "Unable to create CGImage from input data.")
        }
        return try process(cgImage: cgImage, maxDimension: maxDimension, compressionQuality: compressionQuality)
    }
    
    /// Clears any cached screenshot in memory.
    public func clearCache() {
        cacheLock.lock()
        lastHash = nil
        lastResult = nil
        cacheLock.unlock()
    }
}

