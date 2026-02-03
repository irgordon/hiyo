import Foundation
import MLX
import MLXRandom
import Tokenizers

@MainActor
final class MLXProvider: ObservableObject {
    @Published var isAvailable: Bool = false
    @Published var availableModels: [MLXModel] = []
    @Published var isLoading: Bool = false
    @Published var loadingProgress: Double = 0.0
    @Published var currentModel: String = "None"
    
    private var modelContainer: ModelContainer?
    private let modelRegistry = MLXModelRegistry()
    
    init() {
        Task {
            await refreshAvailableModels()
        }
    }
    
    func refreshAvailableModels() async {
        availableModels = modelRegistry.defaultModels
        isAvailable = true
    }
    
    func loadModel(_ modelId: String) async throws {
        isLoading = true
        loadingProgress = 0.0
        
        defer { isLoading = false }
        
        // Validate model ID
        let sanitizedId = try InputValidator.validateModelIdentifier(modelId)
        
        // Check if model exists in cache
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Hiyo/Models", isDirectory: true)
        
        try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        
        // Load model with progress
        let config = ModelConfiguration(
            id: sanitizedId,
            overrideDirectory: cacheDir
        )
        
        // Update progress callback
        let container = try await LLMModelFactory.shared.loadContainer(configuration: config) { [weak self] progress in
            Task { @MainActor in
                self?.loadingProgress = progress.fractionCompleted
            }
        }
        
        self.modelContainer = container
        self.currentModel = sanitizedId
        self.isAvailable = true
        
        SecurityLogger.log(.modelLoaded, details: sanitizedId)
    }
    
    func generate(
        messages: [Message],
        parameters: GenerationParameters = .default
    ) async throws -> AsyncStream<String> {
        guard let container = modelContainer else {
            throw MLXError.modelNotLoaded
        }
        
        // Apply resource limits
        try await ResourceGuard.shared.checkResourceLimits()
        
        return AsyncStream { continuation in
            Task {
                do {
                    let stream = try await container.perform { [weak self] model, tokenizer in
                        // Format messages for chat
                        let prompt = tokenizer.applyChatTemplate(messages: messages)
                        
                        // Tokenize with length check
                        let inputIds = tokenizer.encode(text: prompt)
                        guard inputIds.count < parameters.maxContextLength else {
                            throw MLXError.contextTooLong
                        }
                        
                        // Generate with MLX
                        var generatedTokens: [Int] = []
                        let maxTokens = min(parameters.maxTokens, 4096)
                        
                        for i in 0..<maxTokens {
                            // Prepare input
                            let inputMLX = MLXArray(inputIds + generatedTokens).reshaped([1, -1])
                            
                            // Forward pass
                            let logits = model(inputMLX)
                            let nextTokenLogits = logits[0..., -1, 0...]
                            
                            // Sample
                            let nextToken = sample(
                                logits: nextTokenLogits,
                                temperature: parameters.temperature,
                                topP: parameters.topP
                            )
                            
                            let tokenId = nextToken.item(Int.self)
                            generatedTokens.append(tokenId)
                            
                            // Decode and yield
                            if let text = tokenizer.decode(tokens: [tokenId]) {
                                continuation.yield(text)
                            }
                            
                            // Check for EOS
                            if tokenId == tokenizer.eosTokenId {
                                break
                            }
                            
                            // Update GPU stats
                            await self?.updateGPUStats()
                        }
                        
                        return generatedTokens
                    }
                    
                    _ = try await stream
                    continuation.finish()
                    
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func unloadModel() {
        modelContainer = nil
        currentModel = "None"
        MLX.GPU.clearCache()
        SecurityLogger.log(.modelUnloaded, details: "Memory cleared")
    }
    
    private func sample(logits: MLXArray, temperature: Float, topP: Float) -> MLXArray {
        var processedLogits = logits
        
        // Temperature scaling
        if temperature != 1.0 {
            processedLogits = processedLogits / temperature
        }
        
        // Top-p (nucleus) sampling
        if topP < 1.0 {
            let probs = softMax(processedLogits, axis: -1)
            let sortedIndices = argSort(probs, axis: -1, descending: true)
            let sortedProbs = probs[sortedIndices]
            let cumsumProbs = cumsum(sortedProbs, axis: -1)
            let mask = cumsumProbs > topP
            processedLogits = processedLogits.at(sortedIndices[mask]).set(-Float.infinity)
        }
        
        // Sample from distribution
        return categorical(processedLogits)
    }
    
    private func updateGPUStats() async {
        let activeMemory = MLX.GPU.activeMemory / (1024 * 1024 * 1024) // GB
        let peakMemory = MLX.GPU.peakMemory / (1024 * 1024 * 1024)
        await MainActor.run {
            self.memoryUsage = Double(activeMemory)
        }
    }
}

// MARK: - Supporting Types

struct MLXModel: Identifiable {
    let id: String
    let name: String
    let description: String
    let size: String
    let parameters: String
}

struct GenerationParameters {
    var temperature: Float = 0.7
    var topP: Float = 0.9
    var maxTokens: Int = 1024
    var maxContextLength: Int = 4096
    
    static let `default` = GenerationParameters()
}

enum MLXError: Error {
    case modelNotLoaded
    case contextTooLong
    case generationFailed(String)
    case invalidModel(String)
}
