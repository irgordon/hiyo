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
        SecureMLX.configureSafeLimits()
        isAvailable = true
    }
    
    // MARK: - Model Management
    
    func loadModel(_ modelId: String) async throws {
        loadTask?.cancel()
        
        isLoading = true
        loadingProgress = 0.0
        defer { isLoading = false }
        
        let sanitizedId = try InputValidator.validateModelIdentifier(modelId)
        try Task.checkCancellation()
        
        // Delegate all loading and directory resolution to LLMModelFactory
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
        
        try await ResourceGuard.shared.checkResourceLimits()
        
        let startTime = Date()
        var tokenCount = 0
        
        return AsyncStream { continuation in
            Task {
                do {
                    let stream = try await container.perform { [weak self] _, model, tokenizer in
                        
                        let prompt = LLMGenerator.formatPrompt(messages: messages, tokenizer: tokenizer)
                        let inputIds = tokenizer.encode(text: prompt)
                        
                        try await ResourceGuard.shared.allocateTokens(inputIds.count)
                        
                        let generator = LLMGenerator(model: model, tokenizer: tokenizer, parameters: parameters)
                        
                        for await response in generator.generate(prompt: inputIds) {
                            guard !Task.isCancelled else { break }
                            
                            tokenCount += 1
                            continuation.yield(response.text)
                            
                            await self?.updateMemoryStats()
                        }
                        
                        await ResourceGuard.shared.releaseTokens(tokenCount)
                        
                        let latency = Date().timeIntervalSince(startTime) * 1000
                        SecurityLogger.logPublic(.generationCompleted,
                                                details: "Generated \(tokenCount) tokens in \(Int(latency))ms")
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
    
    // MARK: - Private
    
    private func updateMemoryStats() async {
        let active = Double(MLX.GPU.activeMemory) / 1_073_741_824.0
        await MainActor.run {
            self.memoryUsage = active
        }
    }
}

// MARK: - Generation Logic

struct LLMGenerator: Sendable {
    let model: LLMModel
    let tokenizer: Tokenizer
    let parameters: GenerationParameters

    static func formatPrompt(messages: [LLMMessage], tokenizer: Tokenizer) -> String {
        let lines = messages.map { message -> String in
            switch message.role {
            case "system": return "System: \(message.content)"
            case "user": return "User: \(message.content)"
            case "assistant": return "Assistant: \(message.content)"
            default: return message.content
            }
        }
        
        let joined = lines.joined(separator: "\n")
        return joined.isEmpty ? "Assistant:" : joined + "\nAssistant:"
    }

    func generate(prompt: [Int]) -> AsyncStream<GenerationResponse> {
        AsyncStream { continuation in
            Task {
                do {
                    let maxContext = SecurityLimits.maxContextTokens
                    let truncatedPrompt = prompt.count > maxContext
                        ? Array(prompt.suffix(maxContext))
                        : prompt
                    
                    if prompt.count > maxContext {
                        SecurityLogger.logPublic(.promptTruncated,
                                                 details: "Prompt truncated to \(maxContext) tokens")
                    }

                    var inputIds = truncatedPrompt
                    let cache = model.newCache(parameters: parameters)

                    if inputIds.count > 1 {
                        let prefill = Array(inputIds.dropLast())
                        let inputMLX = MLXArray(prefill).reshaped([1, -1])
                        _ = try model.forwardIncremental(input: inputMLX, cache: cache)
                        inputIds = [inputIds.last!]
                    }

                    let maxTokens = min(parameters.maxTokens, model.maxContextLength)
                    
                    for _ in 0..<maxTokens {
                        guard !Task.isCancelled else { break }
                        
                        let inputMLX = MLXArray(inputIds).reshaped([1, 1])
                        let logits = try model.forwardIncremental(input: inputMLX, cache: cache)
                        let nextLogits = logits[0..., -1, 0...]
                        
                        let nextToken = try sampleToken(from: nextLogits)
                        
                        if let text = tokenizer.decode(tokens: [nextToken]) {
                            continuation.yield(.init(text: text, token: nextToken))
                        }
                        
                        inputIds = [nextToken]
                        
                        if nextToken == tokenizer.eosTokenId {
                            break
                        }
                    }
                    
                    continuation.finish()
                    
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    private func sampleToken(from logits: MLXArray) throws -> Int {
        let sampled = sample(
            logits: logits,
            temperature: parameters.temperature,
            topP: parameters.topP
        )
        
        guard let token = sampled.item(Int.self) as Int? else {
            throw MLXError.generationFailed("Invalid token sampled")
        }
        
        return token
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

            let maskToRemove = (cumsumProbs - sortedProbs) > topP

            if maskToRemove.all().item(Bool.self) == true {
                return categorical(processed)
            }

            processed = processed.at(sortedIndices[maskToRemove]).set(-Float.infinity)
        }
        
        return categorical(processed)
    }
}

// MARK: - Supporting Types

struct GenerationParameters: Sendable {
    var temperature: Float = 0.7
    var topP: Float = 0.9
    var maxTokens: Int = 1024
    
    static let `default` = GenerationParameters()
}

struct GenerationResponse: Sendable {
    let text: String
    let token: Int
}

struct LLMMessage: Sendable {
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
