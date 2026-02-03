//
//  SecureMLX.swift
//  Hiyo
//
//  MLX-specific security controls.
//

import Foundation
import MLX

enum SecureMLX {
    /// Validates model ID for Hugging Face Hub
    static func validateModelID(_ id: String) throws -> String {
        // Reuse main validator
        return try InputValidator.validateModelIdentifier(id)
    }
    
    /// Sanitizes cache directory and checks for symlinks
    static func secureCacheDirectory() throws -> URL {
        let cache = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Hiyo/Models", isDirectory: true)
        
        // Create with secure permissions
        try FileManager.default.createDirectory(
            at: cache,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        
        // Resolve and verify no symlinks
        let resolved = cache.resolvingSymlinksInPath()
        let fm = FileManager.default
        
        // Walk path and verify each component
        var currentPath = resolved
        while currentPath.path != "/" {
            let attrs = try fm.attributesOfItem(atPath: currentPath.path)
            let type = attrs[.type] as? FileAttributeType
            
            if type == .typeSymbolicLink {
                SecurityLogger.log(.sandboxEscapeAttempt, details: "Symlink in cache path: \(currentPath.path)")
                throw MLXSecurityError.symbolicLinkInPath
            }
            
            currentPath = currentPath.deletingLastPathComponent()
        }
        
        return resolved
    }
    
    /// Validates downloaded model weights
    static func validateModelWeights(at url: URL) throws {
        // Check file exists and is readable
        guard FileManager.default.isReadableFile(atPath: url.path) else {
            throw MLXSecurityError.weightsNotReadable
        }
        
        // Check file size is reasonable (not empty, not huge)
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        guard let size = attrs[.size] as? UInt64 else {
            throw MLXSecurityError.invalidWeights
        }
        
        // MLX models typically 100MB - 10GB
        guard size > 1_000_000 && size < 20_000_000_000 else {
            throw MLXSecurityError.invalidWeightsSize(size)
        }
        
        // Verify file extension
        let ext = url.pathExtension.lowercased()
        let allowedExts = ["safetensors", "bin", "mlx", "weights"]
        guard allowedExts.contains(ext) else {
            throw MLXSecurityError.invalidWeightsFormat(ext)
        }
    }
    
    /// Clears all MLX caches securely
    static func clearAllCaches() throws {
        let cacheDir = try secureCacheDirectory()
        
        // Securely delete each file
        let contents = try FileManager.default.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: nil)
        for item in contents {
            try SecureFileManager.secureDelete(at: item)
        }
        
        // Clear MLX GPU cache
        MLX.GPU.clearCache()
        
        SecurityLogger.log(.dataCleared, details: "All MLX caches cleared")
    }
    
    /// Sets safe MLX GPU limits
    static func configureSafeLimits() {
        // Limit cache to 1GB by default
        MLX.GPU.set(cacheLimit: 1024 * 1024 * 1024)
        
        // Limit total memory to 4GB
        MLX.GPU.set(memoryLimit: 4 * 1024 * 1024 * 1024)
        
        // Enable memory warning handling
        // MLX will automatically free cache on pressure
    }
    
    /// Checks if MLX is running in safe mode
    static func verifyMLXConfiguration() -> Bool {
        let cacheLimit = MLX.GPU.cacheLimit
        let memoryLimit = MLX.GPU.memoryLimit
        
        // Verify limits are set
        guard cacheLimit > 0 && cacheLimit <= 8 * 1024 * 1024 * 1024 else {
            return false
        }
        
        guard memoryLimit > 0 && memoryLimit <= 16 * 1024 * 1024 * 1024 else {
            return false
        }
        
        return true
    }
}

enum MLXSecurityError: Error {
    case symbolicLinkInPath
    case weightsNotReadable
    case invalidWeights
    case invalidWeightsSize(UInt64)
    case invalidWeightsFormat(String)
    
    var localizedDescription: String {
        switch self {
        case .symbolicLinkInPath: 
            return "Security violation: symbolic link detected in cache path"
        case .weightsNotReadable: 
            return "Model weights not accessible"
        case .invalidWeights: 
            return "Invalid model weights file"
        case .invalidWeightsSize(let size): 
            return "Model weights size suspicious: \(size) bytes"
        case .invalidWeightsFormat(let ext): 
            return "Unsupported model format: .\(ext)"
        }
    }
}
