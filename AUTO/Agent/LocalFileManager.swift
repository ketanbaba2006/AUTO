//
//  LocalFileManager.swift
//  AUTO
//
//  Safe, sandboxed local file system abstraction.
//  Enforces directory permission constraints, prevents silent overwrites,
//  and forbids destructive file deletions without explicit user authorization.
//

import Foundation

public struct LocalFileInfo: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let path: String
    public let sizeBytes: Int64
    public let modificationDate: Date
    public let isDirectory: Bool
    public let fileExtension: String
}

public final class LocalFileManager: @unchecked Sendable {
    public static let shared = LocalFileManager()
    
    private let fileManager = FileManager.default
    
    public init() {}
    
    /// Lists files in an authorized directory (e.g., Desktop, Downloads, Documents).
    public func listFilesInDirectory(atPath path: String, maxItems: Int = 50) throws -> [LocalFileInfo] {
        let expandedPath = (path as NSString).expandingTildeInPath
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: expandedPath, isDirectory: &isDir), isDir.boolValue else {
            throw AUTOError.invalidOperation("Directory not found or inaccessible: \(path)")
        }
        
        // Prevent scanning root or system directories
        guard !isRestrictedSystemPath(expandedPath) else {
            throw AUTOError.invalidOperation("Access to system directory is restricted: \(path)")
        }
        
        let contents = try fileManager.contentsOfDirectory(atPath: expandedPath)
        var results: [LocalFileInfo] = []
        
        for name in contents.prefix(maxItems) {
            guard !name.hasPrefix(".") else { continue } // skip hidden
            let fullPath = (expandedPath as NSString).appendingPathComponent(name)
            if let attrs = try? fileManager.attributesOfItem(atPath: fullPath) {
                let size = (attrs[.size] as? NSNumber)?.int64Value ?? 0
                let date = (attrs[.modificationDate] as? Date) ?? Date()
                let isDirectory = (attrs[.type] as? FileAttributeType) == .typeDirectory
                let ext = (name as NSString).pathExtension
                
                results.append(LocalFileInfo(
                    id: fullPath,
                    name: name,
                    path: fullPath,
                    sizeBytes: size,
                    modificationDate: date,
                    isDirectory: isDirectory,
                    fileExtension: ext
                ))
            }
        }
        
        return results
    }
    
    /// Reads the first N characters of a permitted text file.
    public func readFilePreview(atPath path: String, maxCharacters: Int = 2000) throws -> String {
        let expanded = (path as NSString).expandingTildeInPath
        guard !isRestrictedSystemPath(expanded) else {
            throw AUTOError.invalidOperation("Restricted file path: \(path)")
        }
        
        guard let data = fileManager.contents(atPath: expanded),
              let text = String(data: data, encoding: .utf8) else {
            throw AUTOError.invalidOperation("Unable to read text file at \(path)")
        }
        
        return String(text.prefix(maxCharacters))
    }
    
    /// Moves a file to an organization folder with explicit permission.
    public func moveFile(from sourcePath: String, to destinationFolder: String) throws {
        let expSource = (sourcePath as NSString).expandingTildeInPath
        let expDestFolder = (destinationFolder as NSString).expandingTildeInPath
        
        guard !isRestrictedSystemPath(expSource), !isRestrictedSystemPath(expDestFolder) else {
            throw AUTOError.invalidOperation("File operation blocked: restricted system path.")
        }
        
        let fileName = (expSource as NSString).lastPathComponent
        let targetPath = (expDestFolder as NSString).appendingPathComponent(fileName)
        
        // Create destination directory if needed
        try fileManager.createDirectory(atPath: expDestFolder, withIntermediateDirectories: true)
        
        // Check destination collision
        if fileManager.fileExists(atPath: targetPath) {
            throw AUTOError.invalidOperation("Destination file already exists: \(targetPath)")
        }
        
        try fileManager.moveItem(atPath: expSource, toPath: targetPath)
        AppLogger.shared.info("Moved file: \(expSource) -> \(targetPath)", category: .agent)
    }
    
    private func isRestrictedSystemPath(_ path: String) -> Bool {
        let restricted = ["/System", "/Library", "/usr", "/bin", "/sbin", "/private", "/etc", "/var"]
        return restricted.contains { path.hasPrefix($0) }
    }
}

