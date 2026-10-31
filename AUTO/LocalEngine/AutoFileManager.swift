//
//  AutoFileManager.swift
//  AUTO
//
//  Native Local Sandboxed File Manager:
//  Restricts file operations strictly to user-accessible directories
//  (~/Desktop, ~/Downloads, ~/Documents) and blocks system paths.
//

import Foundation

public final class AutoFileManager: @unchecked Sendable {
    public static let shared = AutoFileManager()
    
    private let allowedDirectories: [URL]
    private let forbiddenPrefixes: [String] = [
        "/system", "/usr", "/etc", "/bin", "/sbin", "/var",
        "/.ssh", "/library/keychains", "/private"
    ]
    
    private init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        self.allowedDirectories = [
            home.appendingPathComponent("Desktop"),
            home.appendingPathComponent("Downloads"),
            home.appendingPathComponent("Documents")
        ]
    }
    
    public func isPathAllowed(_ path: String) -> Bool {
        let expanded = (path as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: expanded).standardized
        let pathLower = url.path.lowercased()
        
        // Block forbidden system roots
        for forbidden in forbiddenPrefixes {
            if pathLower.hasPrefix(forbidden) {
                return false
            }
        }
        
        // Ensure path is inside allowed user directories
        for allowed in allowedDirectories {
            if pathLower.hasPrefix(allowed.path.lowercased()) {
                return true
            }
        }
        
        return false
    }
    
    public func listDirectory(at path: String) throws -> [String] {
        guard isPathAllowed(path) else {
            throw AUTOError.fileAccessDenied(path: path, reason: "Directory is outside authorized user folders.")
        }
        
        let expanded = (path as NSString).expandingTildeInPath
        let contents = try FileManager.default.contentsOfDirectory(atPath: expanded)
        return contents.filter { !$0.hasPrefix(".") }
    }
    
    public func previewTextFile(at path: String, maxBytes: Int = 10_000) throws -> String {
        guard isPathAllowed(path) else {
            throw AUTOError.fileAccessDenied(path: path, reason: "Path is outside authorized user folders.")
        }
        
        let expanded = (path as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: expanded)
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        
        let data = handle.readData(ofLength: maxBytes)
        guard let text = String(data: data, encoding: .utf8) else {
            throw AUTOError.fileAccessDenied(path: path, reason: "File is not plain UTF-8 text.")
        }
        return text
    }
}

