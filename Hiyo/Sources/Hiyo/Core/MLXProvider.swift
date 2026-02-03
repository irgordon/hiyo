//
//  MLXProvider.swift
//  Hiyo
//
//  MLX Swift integration for local LLM inference.
//

import Foundation
import MLX
import MLXRandom
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
        
        // Load with progress
        let config = ModelConfiguration(id: sanitizedId)
        
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
        messages: [Message],
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
                        let prompt = self?.formatPrompt(messages: messages, tokenizer: tokenizer) ?? ""
                        
                        // Check limits
                        let inputIds = tokenizer.encode(text: prompt)
                        try await ResourceGuard.shared.allocateTokens(inputIds.count)
                        
                        // Stream generation
                        var generatedText = ""
                        
                        for response in streamGenerate(
                            model: model,
                            tokenizer: tokenizer,
                            prompt: inputIds,
                            parameters: parameters
                        ) {
                            // Check cancellation
                            guard !Task.isCancelled else { break }
                            
                            generatedText += response.text
                            tokenCount += 1
                            
                            continuation.yield(response.text)
                            
                            // Update stats
                            await self?.updateMemoryStats()
                        }
                        
                        await ResourceGuard.shared.releaseTokens(tokenCount)
                        
                        // Log stats
                        let latency = Date().timeIntervalSince(startTime) * 1000
                        SecurityLogger.logPublic(.modelLoaded, details: "Generated \(tokenCount) tokens in \(Int(latency))ms")
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
    
    private func formatPrompt(messages: [Message], tokenizer: Tokenizer) -> String {
        // Simple chat format - adjust based on model
        var prompt = ""
        
        for message in messages {
            switch message.role {
            case "system":
                prompt += "System: \(message.content)\n"
            case "user":
                prompt += "User: \(message.content)\n"
            case "assistant":
                prompt += "Assistant: \(message.content)\n"
            default:
                prompt += "\(message.content)\n"
            }
        }
        
        prompt += "Assistant:"
        return prompt
    }
    
    private func streamGenerate(
        model: LLMModel,
        tokenizer: Tokenizer,
        prompt: [Int],
        parameters: GenerationParameters
    ) -> AsyncStream<GenerationResponse> {
        AsyncStream { continuation in
            Task {
                var inputIds = prompt
                let maxTokens = min(parameters.maxTokens, 4096)
                
                for _ in 0..<maxTokens {
                    guard !Task.isCancelled else { break }
                    
                    // Forward pass
                    let inputMLX = MLXArray(inputIds).reshaped([1, -1])
                    let logits = model(inputMLX)
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
                    
                    inputIds.append(nextToken)
                    
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
            let sorted = argSort(probs, axis: -1, descending: true)
            let sortedProbs = probs[sorted]
            let cumsum = cumsum(sortedProbs, axis: -1)
            let mask = cumsum > topP
            processed = processed.at(sorted[mask]).set(-Float.infinity)
        }
        
        return categorical(processed)
    }
    
    private func updateMemoryStats() async {
        let active = Double(MLX.GPU.activeMemory) / 1_073_741_824.0 // GB
        await MainActor.run {
            self.memoryUsage = active
        }
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

struct Message {
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
