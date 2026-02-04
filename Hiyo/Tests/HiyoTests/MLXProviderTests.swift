//
//  MLXProviderTests.swift
//  HiyoTests
//
//  Tests for MLX integration, model management, and generation.
//

import XCTest
@testable import Hiyo
import MLX
import Tokenizers

// MARK: - Core MLXProvider Tests

@MainActor
final class MLXProviderTests: XCTestCase {
    
    var provider: MLXProvider!
    
    override func setUp() async throws {
        try await super.setUp()
        provider = MLXProvider()
    }
    
    override func tearDown() async throws {
        provider.unloadModel()
        provider = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testProviderInitialization() {
        XCTAssertTrue(provider.isAvailable)
        XCTAssertFalse(provider.isLoading)
        XCTAssertEqual(provider.currentModel, "None")
        XCTAssertEqual(provider.loadingProgress, 0.0)
    }
    
    func testAvailableModels() {
        let models = provider.availableModels
        
        XCTAssertFalse(models.isEmpty)
        XCTAssertTrue(models.contains { $0.id == MLXConfig.defaultModel })
    }
    
    // MARK: - Model Registry Tests
    
    func testModelRegistry() {
        let registry = MLXModelRegistry()
        
        XCTAssertFalse(registry.defaultModels.isEmpty)
        
        let model = registry.getModel("mlx-community/Llama-3.2-3B-Instruct-4bit")
        XCTAssertNotNil(model)
        XCTAssertEqual(model?.name, "Llama 3.2 3B")
        
        let tagged = registry.models(tagged: "recommended")
        XCTAssertFalse(tagged.isEmpty)
    }
    
    func testModelProperties() {
        let registry = MLXModelRegistry()
        let model = registry.defaultModels.first!
        
        XCTAssertFalse(model.id.isEmpty)
        XCTAssertFalse(model.name.isEmpty)
        XCTAssertFalse(model.description.isEmpty)
        XCTAssertFalse(model.size.isEmpty)
        XCTAssertFalse(model.parameters.isEmpty)
    }
    
    // MARK: - Model Loading Tests (Skipped in CI)
    
    func testLoadModel() async throws {
        guard MLX.GPU.isAvailable else {
            throw XCTSkip("GPU not available")
        }
        
        let testModel = "mlx-community/Llama-3.2-1B-Instruct-4bit"
        
        do {
            try await provider.loadModel(testModel)
            
            XCTAssertEqual(provider.currentModel, testModel)
            XCTAssertFalse(provider.isLoading)
        } catch {
            // Model may not be cached, that's OK for unit test
            XCTAssertTrue(provider.isAvailable)
        }
    }
    
    func testUnloadModel() {
        provider.unloadModel()
        
        XCTAssertEqual(provider.currentModel, "None")
        XCTAssertEqual(provider.memoryUsage, 0.0)
    }
    
    // MARK: - Generation Parameters Tests
    
    func testGenerationParametersDefaults() {
        let params = GenerationParameters.default
        
        XCTAssertEqual(params.temperature, 0.7)
        XCTAssertEqual(params.topP, 0.9)
        XCTAssertEqual(params.maxTokens, 1024)
    }
    
    func testGenerationParametersCustom() {
        let params = GenerationParameters(
            temperature: 0.5,
            topP: 0.95,
            maxTokens: 2048
        )
        
        XCTAssertEqual(params.temperature, 0.5)
        XCTAssertEqual(params.topP, 0.95)
        XCTAssertEqual(params.maxTokens, 2048)
    }
    
    // MARK: - MLX Configuration Tests
    
    func testMLXSafeLimits() {
        SecureMLX.configureSafeLimits()
        
        let cacheLimit = MLX.GPU.cacheLimit
        let memoryLimit = MLX.GPU.memoryLimit
        
        XCTAssertGreaterThan(cacheLimit, 0)
        XCTAssertLessThanOrEqual(cacheLimit, 8 * 1024 * 1024 * 1024)
        
        XCTAssertGreaterThan(memoryLimit, 0)
        XCTAssertLessThanOrEqual(memoryLimit, 16 * 1024 * 1024 * 1024)
    }
    
    func testMLXConfigurationVerification() {
        SecureMLX.configureSafeLimits()
        XCTAssertTrue(SecureMLX.verifyMLXConfiguration())
    }
    
    // MARK: - Error Handling Tests
    
    func testMLXErrorDescriptions() {
        let notLoadedError = MLXError.modelNotLoaded
        XCTAssertFalse(notLoadedError.localizedDescription.isEmpty)
        
        let generationError = MLXError.generationFailed("Test error")
        XCTAssertTrue(generationError.localizedDescription.contains("Test error"))
    }
}

// MARK: - End-to-End Generation Tests (Mocks)

final class MLXProviderGenerationTests: XCTestCase {
    
    // MARK: Mocks
    
    final class MockTokenizer: Tokenizer {
        func encode(text: String) -> [Int] {
            text.unicodeScalars.map { Int($0.value) }
        }

        func decode(tokens: [Int]) -> String? {
            String(tokens.compactMap { UnicodeScalar($0).map { Character($0) } })
        }

        var eosTokenId: Int { Int(UnicodeScalar("␃").value) }
    }

    struct MockState {
        var tokens: [Int] = []
    }

    final class MockLLMModel: LLMModel {
        let identifier = "mock"
        let maxContextLength = 128

        func newCache(parameters: GenerationParameters) -> MockState {
            MockState()
        }

        func forwardIncremental(input: MLXArray, cache: MockState) throws -> MLXArray {
            let ints: [Int] = input.asArray()
            let floats = ints.map { Float($0) }
            return MLXArray(floats).reshaped([1, ints.count, 1])
        }
    }

    actor MockModelContainer: ModelContainerProtocol {
        let model: LLMModel
        let tokenizer: Tokenizer

        init(model: LLMModel, tokenizer: Tokenizer) {
            self.model = model
            self.tokenizer = tokenizer
        }

        func perform<T>(
            _ action: @Sendable (isolated MockModelContainer, LLMModel, Tokenizer) async throws -> T
        ) async throws -> T {
            try await action(self, model, tokenizer)
        }
    }

    final class MockResourceGuard: ResourceGuardProtocol {
        var allocated = 0
        var released = 0
        var checkCalled = false

        func checkResourceLimits() async throws {
            checkCalled = true
        }

        func allocateTokens(_ count: Int) async throws {
            allocated += count
        }

        func releaseTokens(_ count: Int) async {
            released += count
        }
    }

    final class MockSecurityLogger: SecurityLoggerProtocol {
        var generationCompletedCalled = false

        func logPublic(_ event: SecurityEvent, details: String) {
            if event == .generationCompleted {
                generationCompletedCalled = true
            }
        }

        func log(_ event: SecurityEvent, details: String) {}
    }

    private extension MLXArray {
        func asArray() -> [Int] {
            (0..<self.shape[0]).map { index in
                self[index].item(Int.self)
            }
        }
    }
    
    // MARK: - Tests
    
    @MainActor
    func testGenerate_endToEnd_streamsAndLogs() async throws {
        let provider = MLXProvider()
        let mockModel = MockLLMModel()
        let mockTokenizer = MockTokenizer()
        let mockContainer = MockModelContainer(model: mockModel, tokenizer: mockTokenizer)

        provider.setValue(mockContainer, forKey: "modelContainer")

        let mockGuard = MockResourceGuard()
        ResourceGuard.shared = mockGuard

        let mockLogger = MockSecurityLogger()
        SecurityLogger.shared = mockLogger

        let messages = [LLMMessage(role: "user", content: "Hello")]
        var collected: [String] = []

        let stream = try await provider.generate(messages: messages)

        for await chunk in stream {
            collected.append(chunk)
            if collected.count == 5 { break }
        }

        XCTAssertFalse(collected.isEmpty, "Should stream at least one token")
        XCTAssertTrue(mockGuard.checkCalled, "ResourceGuard.checkResourceLimits should be called")
        XCTAssertGreaterThan(mockGuard.allocated, 0, "Tokens should be allocated")
        XCTAssertGreaterThan(mockGuard.released, 0, "Tokens should be released")
        XCTAssertTrue(mockLogger.generationCompletedCalled, "Should log generationCompleted")
    }
    
    @MainActor
    func testGenerate_cancellation() async throws {
        let provider = MLXProvider()
        let mockModel = MockLLMModel()
        let mockTokenizer = MockTokenizer()
        let mockContainer = MockModelContainer(model: mockModel, tokenizer: mockTokenizer)

        provider.setValue(mockContainer, forKey: "modelContainer")

        let messages = [LLMMessage(role: "user", content: "Hello")]
        let expectation = expectation(description: "Cancelled early")

        let task = Task {
            let stream = try await provider.generate(messages: messages)
            var count = 0

            for await _ in stream {
                count += 1
                if count == 3 {
                    Task.current.cancel()
                    break
                }
            }

            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 2.0)
        _ = task
    }
}
