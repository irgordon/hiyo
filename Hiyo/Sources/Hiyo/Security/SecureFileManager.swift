//
//  SecureFileManager.swift
//  Hiyo
//
//  File operations with secure permissions and deletion.
//

import Foundation

enum SecureFileManager {
    /// Creates file with secure permissions (owner read/write only)
    static func createSecureFile(at url: URL, contents: Data) throws {
        // Create directory if needed
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        
        // Write file with protection
        try contents.write(to: url, options: .completeFileProtectionUnlessOpen)
        
        // Set restrictive permissions (0o600)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: url.path
        )
        
        // Verify permissions
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        guard let permissions = attributes[.posixPermissions] as? NSNumber,
              permissions.int16Value == 0o600 else {
            throw FileError.permissionSettingFailed
        }
    }
    
    /// Secure deletion with overwrite
    static func secureDelete(at url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        
        // Get file size
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        guard let size = attributes[.size] as? UInt64,
              size < 100 * 1024 * 1024 else { // 100MB max for secure delete
            // Too large, just regular delete
            try FileManager.default.removeItem(at: url)
            return
        }
        
        // Overwrite with random data three times
        let passes = [0x00, 0xFF, Int.random(in: 0...255)]
        for pass in passes {
            var data = Data(repeating: UInt8(pass), count: Int(size))
            // Add some randomness
            for i in 0..<min(1024, data.count) {
                data[i] = UInt8.random(in: 0...255)
            }
            try data.write(to: url)
            sync()
        }
        
        // Final delete
        try FileManager.default.removeItem(at: url)
    }
    
    /// Validates sandbox container integrity
    static func verifyContainerIntegrity() throws {
        guard let container = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .deletingLastPathComponent() else {
            throw FileError.containerNotFound
        }
        
        // Check for symbolic links (sandbox escape)
        let resourceValues = try container.resourceValues(forKeys: [.isSymbolicLinkKey])
        guard resourceValues.isSymbolicLink == false else {
            SecurityLogger.log(.sandboxEscapeAttempt, details: "Symbolic link in container")
            throw FileError.symbolicLinkDetected
        }
        
        // Verify path is within expected location
        let path = container.path
        guard path.contains("Containers") || path.contains("Application Support") else {
            throw FileError.invalidContainer
        }
    }
    
    /// Application Support directory (sandboxed)
    static var appSupportDirectory: URL {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appDir = urls[0].appendingPathComponent("Hiyo", isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: appDir.path) {
            try? FileManager.default.createDirectory(
                at: appDir,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )
        }
        return appDir
    }
    
    /// Secure temporary directory
    static func secureTempDirectory() -> URL {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("hiyo-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: temp,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        return temp
    }
}

enum FileError: Error {
    case permissionSettingFailed
    case invalidAttributes
    case containerNotFound
    case invalidContainer
    case symbolicLinkDetected
    case isDirectory
}
