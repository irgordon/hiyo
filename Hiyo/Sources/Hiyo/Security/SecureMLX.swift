//
//  SecureMLX.swift
//  Hiyo
//
//  MLX-specific security controls.
//

import Foundation
import MLX

// MARK: - Policy

private enum SecureMLXPolicy {
    static let cacheSubdirectory = "Hiyo/Models"

    // Heuristic model size bounds (bytes)
    static let minModelSize: UInt64 = 1_000_000        // ~1 MB
    static let maxModelSize: UInt64 = 20_000_000_000   // ~20 GB

    // Allowed model file extensions
    static let allowedExtensions = ["safetensors", "bin", "mlx", "weights"]
}

enum SecureMLX {
    /// Validates model ID for Hugging Face Hub
    static func validateModelID(_ id: String) throws -> String {
        // Reuse main validator
        return try InputValidator.validateModelIdentifier(id)
    }

    /// Sanitizes cache directory and checks for symlinks
    static func secureCacheDirectory() throws -> URL {
        let fm = FileManager.default

        guard let baseCache = fm.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            throw MLXSecurityError.cacheDirectoryUnavailable
        }

        let cache = baseCache.appendingPathComponent(SecureMLXPolicy.cacheSubdirectory, isDirectory: true)

        // Create with secure permissions
        try fm.createDirectory(
            at: cache,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )

        // Resolve and verify no symlinks in the path chain
        let resolved = cache.resolvingSymlinksInPath()

        var currentURL = resolved
        // Walk up until we reach the base cache directory or root
        while currentURL.path != baseCache.path && currentURL.path != "/" {
            let resourceValues = try currentURL.resourceValues(forKeys: [.isSymbolicLinkKey])
            if resourceValues.isSymbolicLink == true {
                SecurityLogger.log(
                    .sandboxEscapeAttempt,
                    details: "Symlink detected in MLX cache path"
                )
                throw MLXSecurityError.symbolicLinkInPath
            }
            currentURL.deleteLastPathComponent()
        }

        return resolved
    }

    /// Validates downloaded model weights
    static func validateModelWeights(at url: URL) throws {
        let fm = FileManager.default

        // Check file exists and is readable
        guard fm.isReadableFile(atPath: url.path) else {
            throw MLXSecurityError.weightsNotReadable
        }

        // Check file size is reasonable (not empty, not huge)
        let attrs = try fm.attributesOfItem(atPath: url.path)
        guard let size = attrs[.size] as? UInt64 else {
            throw MLXSecurityError.invalidWeights
        }

        guard size >= SecureMLXPolicy.minModelSize,
              size <= SecureMLXPolicy.maxModelSize else {
            throw MLXSecurityError.invalidWeightsSize(size)
        }

        // Verify file extension
        let ext = url.pathExtension.lowercased()
        guard SecureMLXPolicy.allowedExtensions.contains(ext) else {
            throw MLXSecurityError.invalidWeightsFormat(ext)
        }
    }

    /// Clears all MLX caches securely
    static func clearAllCaches() async throws {
        let cacheDir = try secureCacheDirectory()

        // Securely delete each file
        let contents = try FileManager.default.contentsOfDirectory(
            at: cacheDir,
            includingPropertiesForKeys: nil
        )

        for item in contents {
            try await SecureFileManager.secureDelete(at: item)
        }

        // Clear MLX GPU cache
        MLX.GPU.clearCache()

        SecurityLogger.log(.dataCleared, details: "All MLX caches cleared")
    }

    /// Sets safe MLX GPU limits (adaptive where possible)
    static func configureSafeLimits() {
        // Prefer adaptive limits based on total GPU memory if available.
        let totalMemory = MLX.GPU.totalMemory() ?? (8 * 1024 * 1024 * 1024) // Assume 8 GB if unknown

        let cacheLimit = totalMemory / 8      // ~12.5% for cache
        let memoryLimit = totalMemory / 2     // ~50% overall limit

        MLX.GPU.set(cacheLimit: cacheLimit)
        MLX.GPU.set(memoryLimit: memoryLimit)
    }

    /// Checks if MLX is running in safe mode
    @discardableResult
    static func verifyMLXConfiguration() -> Bool {
        let cacheLimit = MLX.GPU.cacheLimit
        let memoryLimit = MLX.GPU.memoryLimit
        let totalMemory = MLX.GPU.totalMemory() ?? (16 * 1024 * 1024 * 1024) // Assume 16 GB if unknown

        let cacheOK = cacheLimit > 0 && cacheLimit <= totalMemory
        let memoryOK = memoryLimit > 0 && memoryLimit <= totalMemory

        let isSafe = cacheOK && memoryOK

        if !isSafe {
            SecurityLogger.log(
                .configurationError,
                details: "MLX GPU limits out of expected range (cache: \(cacheLimit), memory: \(memoryLimit))"
            )
        }

        return isSafe
    }
}

enum MLXSecurityError: LocalizedError {
    case cacheDirectoryUnavailable
    case symbolicLinkInPath
    case weightsNotReadable
    case invalidWeights
    case invalidWeightsSize(UInt64)
    case invalidWeightsFormat(String)

    var errorDescription: String? {
        switch self {
        case .cacheDirectoryUnavailable:
            return "Unable to locate a valid cache directory for MLX."
        case .symbolicLinkInPath:
            return "Security violation: symbolic link detected in MLX cache path."
        case .weightsNotReadable:
            return "Model weights are not accessible."
        case .invalidWeights:
            return "Invalid model weights file."
        case .invalidWeightsSize(let size):
            return "Model weights size is suspicious: \(size) bytes."
        case .invalidWeightsFormat(let ext):
            return "Unsupported model format: .\(ext)."
        }
    }
}
