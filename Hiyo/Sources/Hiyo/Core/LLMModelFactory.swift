//
//  LLMModelFactory.swift
//  Hiyo
//
//  Secure, production‑ready implementation scaffold.
//

import Foundation
import MLX
import Tokenizers
import Hub

// MARK: - Errors

public enum LLMModelFactoryError: LocalizedError {
    case unsupportedModel(String)
    case invalidDirectory(URL)
    case directoryNotAccessible(URL)
    case loadingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .unsupportedModel(let id):
            return "The model '\(id)' is not supported."
        case .invalidDirectory(let url):
            return "Invalid model directory: \(url.path)"
        case .directoryNotAccessible(let url):
            return "Model directory is not accessible: \(url.path)"
        case .loadingFailed(let reason):
            return "Failed to load model: \(reason)"
        }
    }
}

// MARK: - Factory

public final class LLMModelFactory: Sendable {
    public static let shared = LLMModelFactory()

    private let logger = SecurityLogger.self

    /// Allowlist of supported model IDs.
    /// This prevents loading arbitrary or malicious model paths.
    private let supportedModels: Set<String> = [
        "mlx-community/Llama-3.2-1B-Instruct-4bit",
        "mlx-community/Llama-3.2-3B-Instruct-4bit",
        "mlx-community/Llama-3.2-8B-Instruct-4bit",
        "mlx-community/Qwen2.5-7B-Instruct-4bit",
        "mlx-community/Qwen2.5-14B-Instruct-4bit",
        "mlx-community/Mistral-7B-Instruct-v0.3-4bit",
        "mlx-community/Phi-3-mini-4k-instruct-4bit",
        "mlx-community/CodeLlama-7B-Instruct-4bit"
    ]

    private init() {}

    // MARK: - Public API

    public func loadContainer(
        configuration: ModelConfiguration,
        progressHandler: @escaping @Sendable (Progress) -> Void
    ) async throws -> ModelContainer {

        try Task.checkCancellation()

        let modelId = try validateModelIdentifier(configuration.id)

        // Configure Hub with SecureMLX cache
        // This ensures models are downloaded to and loaded from the secure cache directory.
        let secureCache = try SecureMLX.secureCacheDirectory()
        let hub = HubApi(downloadBase: secureCache)

        logger.logPublic(.modelLoaded, details: "Loading model \(modelId)")

        // Use the shared loadModelContainer from Load.swift which handles
        // downloading (if needed) and loading the model.
        return try await loadModelContainer(
            hub: hub,
            configuration: configuration,
            progressHandler: progressHandler
        )
    }

    // MARK: - Validation

    private func validateModelIdentifier(_ id: String) throws -> String {
        // Also check if the ID is in the allowlist.
        // Note: The caller might pass an ID that isn't in our hardcoded list but is valid.
        // However, strictly enforcing the allowlist is safer.
        // If MLXConfig.recommendedModels contains more models, we should update this list or use that.
        // For now, we trust the supportedModels set defined here.
        guard supportedModels.contains(id) else {
            logger.log(.modelLoadFailed, details: "Unsupported model id: \(id)")
            throw LLMModelFactoryError.unsupportedModel(id)
        }
        return id
    }
}
