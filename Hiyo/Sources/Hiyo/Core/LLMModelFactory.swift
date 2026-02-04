//
//  LLMModelFactory.swift
//  Hiyo
//
//  Secure, production‑ready implementation scaffold.
//

import Foundation
import MLX
import Tokenizers

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
        "mlx-community/Qwen2.5-14B-Instruct-4bit"
    ]

    private init() {}

    // MARK: - Public API

    public func loadContainer(
        configuration: ModelConfiguration,
        progressHandler: @escaping (Progress) -> Void
    ) async throws -> ModelContainer {

        try Task.checkCancellation()

        let modelId = try validateModelIdentifier(configuration.id)
        let directory = try resolveModelDirectory(
            override: configuration.overrideDirectory,
            modelId: modelId
        )

        logger.logPublic(.modelLoaded, details: "Loading model \(modelId)")

        let progress = Progress(totalUnitCount: 100)
        progressHandler(progress)

        // Heavy work off the main actor
        let (model, tokenizer) = try await loadModelAndTokenizer(
            id: modelId,
            directory: directory,
            progress: progress,
            progressHandler: progressHandler
        )

        return ModelContainer(model: model, tokenizer: tokenizer)
    }

    // MARK: - Validation

    private func validateModelIdentifier(_ id: String) throws -> String {
        guard supportedModels.contains(id) else {
            logger.log(.modelLoadFailed, details: "Unsupported model id: \(id)")
            throw LLMModelFactoryError.unsupportedModel(id)
        }
        return id
    }

    private func resolveModelDirectory(override: URL?, modelId: String) throws -> URL {
        if let override {
            guard override.isFileURL else {
                throw LLMModelFactoryError.invalidDirectory(override)
            }
            guard FileManager.default.directoryExists(override) else {
                throw LLMModelFactoryError.directoryNotAccessible(override)
            }
            guard override.isSafePath else {
                throw LLMModelFactoryError.invalidDirectory(override)
            }
            return override
        }

        // Default: ~/Library/Application Support/Hiyo/Models/<sanitized>
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = base.appendingPathComponent("Hiyo", isDirectory: true)
        let modelsDir = appDir.appendingPathComponent("Models", isDirectory: true)

        let sanitized = modelId.replacingOccurrences(of: "/", with: "_")
        let modelDir = modelsDir.appendingPathComponent(sanitized, isDirectory: true)

        guard FileManager.default.directoryExists(modelDir) else {
            throw LLMModelFactoryError.directoryNotAccessible(modelDir)
        }

        guard modelDir.isSafePath else {
            throw LLMModelFactoryError.invalidDirectory(modelDir)
        }

        return modelDir
    }

    // MARK: - Loading Implementation

    private func loadModelAndTokenizer(
        id: String,
        directory: URL,
        progress: Progress,
        progressHandler: @escaping (Progress) -> Void
    ) async throws -> (LLMModel, Tokenizer) {

        try Task.checkCancellation()

        // Step 1: Load tokenizer
        progress.completedUnitCount = 10
        progressHandler(progress)

        let tokenizer = try await loadTokenizer(for: id, directory: directory)

        progress.completedUnitCount = 40
        progressHandler(progress)

        // Step 2: Load model weights + graph
        let model = try await loadLLMModel(for: id, directory: directory)

        progress.completedUnitCount = 100
        progressHandler(progress)

        return (model, tokenizer)
    }

    // MARK: - Tokenizer / Model Loaders (to be implemented)

    private func loadTokenizer(for id: String, directory: URL) async throws -> Tokenizer {
        // TODO: Implement using your tokenizer JSON/BPE files
        throw LLMModelFactoryError.loadingFailed("Tokenizer loader not implemented for \(id)")
    }

    private func loadLLMModel(for id: String, directory: URL) async throws -> LLMModel {
        // TODO: Implement using MLX graph + weights
        throw LLMModelFactoryError.loadingFailed("Model loader not implemented for \(id)")
    }
}

// MARK: - FileManager Helpers

private extension FileManager {
    func directoryExists(_ url: URL) -> Bool {
        var isDir: ObjCBool = false
        return fileExists(atPath: url.path, isDir: &isDir) && isDir.boolValue
    }
}

// MARK: - Path Safety

private extension URL {
    /// Prevents path traversal and symlink escape.
    var isSafePath: Bool {
        let resolved = (try? self.resolvingSymlinksInPath()) ?? self
        return resolved.path.hasPrefix(NSHomeDirectory())
    }
}
