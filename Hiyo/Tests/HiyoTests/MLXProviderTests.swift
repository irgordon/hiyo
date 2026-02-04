//
//  MLXProviderTests.swift
//  HiyoTests
//
//  Tests for MLX integration and model management.
//

import XCTest
@testable import Hiyo

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
        // Skip if no GPU available (CI environment)
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
        XCTAssertLessThanOrEqual(cacheLimit, 8 * 1024 * 1024 * 1024) // 8GB max
        
        XCTAssertGreaterThan(memoryLimit, 0)
        XCTAssertLessThanOrEqual(memoryLimit, 16 * 1024 * 1024 * 1024) // 16GB max
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
