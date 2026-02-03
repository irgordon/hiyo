// SecureMLX.swift - Additional security for MLX
import Foundation
import MLX

enum SecureMLX {
    /// Validates model ID prevents path traversal
    static func validateModelID(_ id: String) throws -> String {
        // Only allow Hugging Face model IDs (user/model-name)
        let pattern = "^[a-zA-Z0-9_-]+/[a-zA-Z0-9._-]+$"
        guard id.range(of: pattern, options: .regularExpression) != nil else {
            throw MLXSecurityError.invalidModelID
        }
        
        // Block path traversal attempts
        guard !id.contains("..") && !id.contains("/../") else {
            throw MLXSecurityError.pathTraversalAttempted
        }
        
        return id
    }
    
    /// Sanitizes cache directory
    static func secureCacheDirectory() throws -> URL {
        let cache = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Hiyo/Models", isDirectory: true)
        
        // Ensure no symlinks in path
        let resolved = cache.resolvingSymlinksInPath()
        guard resolved.path.contains("Caches") else {
            throw MLXSecurityError.invalidCachePath
        }
        
        return resolved
    }
    
    /// Clears all model caches
    static func clearAllCaches() throws {
        let cacheDir = try secureCacheDirectory()
        let contents = try FileManager.default.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: nil)
        for item in contents {
            try SecureFileManager.secureDelete(at: item)
        }
    }
}

enum MLXSecurityError: Error {
    case invalidModelID
    case pathTraversalAttempted
    case invalidCachePath
}
