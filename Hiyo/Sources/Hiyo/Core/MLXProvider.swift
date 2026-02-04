//
//  MLXProvider.swift
//  Hiyo
//
//  MLX Swift integration for local LLM inference.
//

import Foundation
import MLX
import MLXRandom
import MLXNN
import Tokenizers

@MainActor
final class MLXProvider: ObservableObject {
    @Published var isAvailable: Bool = false
    @Published var isLoading: Bool = false
    @Published var loadingProgress: Double = 0.0
    @Published var currentModel: String = "None"
    @Published var memoryUsage: Double = 0.0
    
    var availableModels: [MLXModel] {
        modelRegistry.defaultModels
    }
    
    private var modelContainer: ModelContainer?
    private let modelRegistry = MLXModelRegistry()
    private var loadTask: Task<Void, Error>?
    
    init() {
        // Configure safe defaults
        SecureMLX.configureSafeLimits()
        isAvailable = true
    }
    
    // MARK: - Model Management
    
    func loadModel(_ modelId: String) async throws {
        // Cancel existing load
        loadTask?.cancel()
        
        isLoading = true
        loadingProgress = 0.0
        defer { isLoading = false }
        
        // Validate
        let sanitizedId = try InputValidator.validateModelIdentifier(modelId)
        
        // Check cancellation
        try Task.checkCancellation()
        
        // Check for local override (sideloaded model)
        // We append the model ID (replacing / with _) to avoid collisions
        let safeModelName = sanitizedId.replacingOccurrences(of: "/", with: "_")
        let secureCacheDir = try SecureMLX.secureCacheDirectory()
        let localModelDir = secureCacheDir.appendingPathComponent(safeModelName)

        let overrideURL: URL?
        if FileManager.default.fileExists(atPath: localModelDir.appendingPathComponent("config.json").path) {
            overrideURL = localModelDir
            SecurityLogger.logPublic(.modelLoaded, details: "Using local override for \(sanitizedId)")
        } else {
            // Fallback to Hub download (managed by swift-transformers in standard cache)
            overrideURL = nil
        }

        // Load with progress
        let config = ModelConfiguration(
            id: sanitizedId,
            overrideDirectory: overrideURL
        )
        
        loadTask = Task {
            self.modelContainer = try await LLMModelFactory.shared.loadContainer(
                configuration: config
            ) { [weak self] progress in
                Task { @MainActor in
                    self?.loadingProgress = progress.fractionCompleted
                    self?.currentModel = sanitizedId
                }
            }
            
            await MainActor.run {
                self.isAvailable = true
                self.currentModel = sanitizedId
                SecurityLogger.log(.modelLoaded, details: sanitizedId)
            }
        }
        
        try await loadTask?.value
    }
    
    func unloadModel() {
        modelContainer = nil
        currentModel = "None"
        MLX.GPU.clearCache()
        memoryUsage = 0.0
        SecurityLogger.log(.modelUnloaded, details: "Memory cleared")
    }
    
    func refreshAvailableModels() {
        // Models are statically defined in registry
        objectWillChange.send()
    }
    
    // MARK: - Generation
    
    func generate(
        messages: [LLMMessage],
        parameters: GenerationParameters = .default
    ) async throws -> AsyncStream<String> {
        guard let container = modelContainer else {
            throw MLXError.modelNotLoaded
        }
        
        // Resource check
        try await ResourceGuard.shared.checkResourceLimits()
        
        let startTime = Date()
        var tokenCount = 0
        
        return AsyncStream { continuation in
            Task {
                do {
                    let stream = try await container.perform { [weak self] model, tokenizer in
                        // Format prompt
                        let prompt = LLMGenerator.formatPrompt(messages: messages, tokenizer: tokenizer)
                        
                        // Check limits
                        let inputIds = tokenizer.encode(text: prompt)
                        try await ResourceGuard.shared.allocateTokens(inputIds.count)
                        
                        // Stream generation
                        let generator = LLMGenerator(model: model, tokenizer: tokenizer, parameters: parameters)
                        for await response in generator.generate(prompt: inputIds) {
                            // Check cancellation
                            guard !Task.isCancelled else { break }
                            
                            tokenCount += 1
                            
                            continuation.yield(response.text)
                            
                            // Update stats
                            await self?.updateMemoryStats()
                        }
                        
                        await ResourceGuard.shared.releaseTokens(tokenCount)
                        
                        // Log stats
                        let latency = Date().timeIntervalSince(startTime) * 1000
                        SecurityLogger.logPublic(.generationCompleted, details: "Generated \(tokenCount) tokens in \(Int(latency))ms")
                    }
                    
                    _ = try await stream
                    continuation.finish()
                    
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func updateMemoryStats() async {
        let active = Double(MLX.GPU.activeMemory) / 1_073_741_824.0 // GB
        await MainActor.run {
            self.memoryUsage = active
        }
    }
}

// MARK: - Generation Logic

/// Helper struct to handle model generation logic outside of MainActor
struct LLMGenerator {
    let model: LLMModel
    let tokenizer: Tokenizer
    let parameters: GenerationParameters

    static func formatPrompt(messages: [LLMMessage], tokenizer: Tokenizer) -> String {
        // Simple chat format - adjust based on model
        let lines = messages.map { message -> String in
            switch message.role {
            case "system":
                return "System: \(message.content)"
            case "user":
                return "User: \(message.content)"
            case "assistant":
                return "Assistant: \(message.content)"
            default:
                return "\(message.content)"
            }
        }
        
        let joined = lines.joined(separator: "\n")
        return joined.isEmpty ? "Assistant:" : joined + "\nAssistant:"
    }

    func generate(prompt: [Int]) -> AsyncStream<GenerationResponse> {
        AsyncStream { continuation in
            Task {
                // Truncate input to security limit
                let maxContext = SecurityLimits.maxContextTokens
                let truncatedPrompt: [Int]
                if prompt.count > maxContext {
                    truncatedPrompt = Array(prompt.suffix(maxContext))
                    print("Warning: Prompt truncated to \(maxContext) tokens")
                } else {
                    truncatedPrompt = prompt
                }

                var inputIds = truncatedPrompt

                // Initialize cache
                let cache = model.newCache(parameters: parameters)

                // Prefill
                if inputIds.count > 1 {
                    let inputMLX = MLXArray(inputIds.dropLast()).reshaped([1, -1])
                    _ = model(inputMLX, cache: cache)
                    // cache is updated in-place

                    // The last token is the first input for generation loop
                    inputIds = [inputIds.last!]
                }

                let maxTokens = min(parameters.maxTokens, 4096)
                
                for _ in 0..<maxTokens {
                    guard !Task.isCancelled else { break }
                    
                    // Forward pass with cache
                    let inputMLX = MLXArray(inputIds).reshaped([1, -1])
                    let logits = model(inputMLX, cache: cache)
                    // cache is updated in-place

                    let nextLogits = logits[0..., -1, 0...]
                    
                    // Sample
                    let nextToken = sample(
                        logits: nextLogits,
                        temperature: parameters.temperature,
                        topP: parameters.topP
                    ).item(Int.self)
                    
                    // Decode
                    if let text = tokenizer.decode(tokens: [nextToken]) {
                        continuation.yield(GenerationResponse(text: text, token: nextToken))
                    }
                    
                    inputIds = [nextToken]
                    
                    // Check for EOS
                    if nextToken == tokenizer.eosTokenId {
                        break
                    }
                }
                
                continuation.finish()
            }
        }
    }
    
    private func sample(logits: MLXArray, temperature: Float, topP: Float) -> MLXArray {
        var processed = logits
        
        if temperature != 1.0 {
            processed = processed / temperature
        }
        
        if topP < 1.0 {
            let probs = softMax(processed, axis: -1)
            let sortedIndices = argSort(probs, axis: -1, descending: true)
            let sortedProbs = probs[sortedIndices]
            let cumsumProbs = cumsum(sortedProbs, axis: -1)

            // Mask where cumulative probability > topP, but keep at least one token.
            // We want to mask where (cumsum - prob) > topP.
            let maskToRemove = (cumsumProbs - sortedProbs) > topP

            // Apply mask
            processed = processed.at(sortedIndices[maskToRemove]).set(-Float.infinity)
        }
        
        return categorical(processed)
    }
}

// MARK: - Supporting Types

struct GenerationParameters {
    var temperature: Float = 0.7
    var topP: Float = 0.9
    var maxTokens: Int = 1024
    
    static let `default` = GenerationParameters()
}

struct GenerationResponse {
    let text: String
    let token: Int
}

struct LLMMessage {
    let role: String
    let content: String
}

enum MLXError: Error {
    case modelNotLoaded
    case generationFailed(String)
    case cancelled
    
    var localizedDescription: String {
        switch self {
        case .modelNotLoaded:
            return "No model loaded. Please select a model in Settings."
        case .generationFailed(let msg):
            return "Generation failed: \(msg)"
        case .cancelled:
            return "Generation cancelled."
        }
    }
}
