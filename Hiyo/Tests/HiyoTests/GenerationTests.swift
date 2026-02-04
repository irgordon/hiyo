//
//  GenerationTests.swift
//  HiyoTests
//

import XCTest
@testable import Hiyo
import MLX
import Tokenizers

// MARK: - Mocks

final class MockTokenizer: Tokenizer {
    // Simple 1:1 mapping: each character → its unicode scalar value
    func encode(text: String) -> [Int] {
        text.unicodeScalars.map { Int($0.value) }
    }

    func decode(tokens: [Int]) -> String? {
        String(tokens.compactMap { UnicodeScalar($0).map { Character($0) } })
    }

    var eosTokenId: Int { Int(UnicodeScalar("␃").value) } // End-of-text marker
}

struct MockState {
    var tokens: [Int] = []
}

final class MockLLMModel: LLMModel {
    let identifier: String = "mock"
    let maxContextLength: Int = 128

    // We simulate a KV cache by just tracking tokens we've seen.
    func newCache(parameters: GenerationParameters) -> MockState {
        MockState()
    }

    func forwardIncremental(input: MLXArray, cache: MockState) throws -> MLXArray {
        // For testing: logits are just the input tokens echoed back.
        // Shape: [1, sequenceLength, vocabSize] is faked as [1, sequenceLength, 1]
        // where the "logit" is the token id itself.
        let ints: [Int] = input.asArray()
        let floats = ints.map { Float($0) }
        return MLXArray(floats).reshaped([1, ints.count, 1])
    }
}

// Helper to extract Swift array from MLXArray in tests
private extension MLXArray {
    func asArray() -> [Int] {
        // This is a test-only helper; in real code you'd use proper MLX APIs.
        // Assume 1D for simplicity.
        (0..<self.shape[0]).map { index in
            self[index].item(Int.self)
        }
    }
}

// MARK: - Tests

final class GenerationTests: XCTestCase {

    func testFormatPrompt_basicRoles() {
        let messages = [
            LLMMessage(role: "system", content: "You are a test."),
            LLMMessage(role: "user", content: "Hello"),
            LLMMessage(role: "assistant", content: "Hi there")
        ]

        let tokenizer = MockTokenizer()
        let prompt = LLMGenerator.formatPrompt(messages: messages, tokenizer: tokenizer)

        XCTAssertTrue(prompt.contains("System: You are a test."))
        XCTAssertTrue(prompt.contains("User: Hello"))
        XCTAssertTrue(prompt.contains("Assistant: Hi there"))
        XCTAssertTrue(prompt.hasSuffix("Assistant:"))
    }

    func testFormatPrompt_emptyMessages() {
        let tokenizer = MockTokenizer()
        let prompt = LLMGenerator.formatPrompt(messages: [], tokenizer: tokenizer)
        XCTAssertEqual(prompt, "Assistant:")
    }

    func testGeneration_streamsTokens() async throws {
        let model = MockLLMModel()
        let tokenizer = MockTokenizer()
        let params = GenerationParameters(temperature: 1.0, topP: 1.0, maxTokens: 5)

        let generator = LLMGenerator(model: model, tokenizer: tokenizer, parameters: params)

        let promptTokens = tokenizer.encode(text: "abc")
        var collected: [String] = []

        for await chunk in generator.generate(prompt: promptTokens) {
            collected.append(chunk.text)
        }

        // With the mock model, we expect some non-empty output
        XCTAssertFalse(collected.isEmpty)
    }

    func testGeneration_respectsMaxTokens() async throws {
        let model = MockLLMModel()
        let tokenizer = MockTokenizer()
        let params = GenerationParameters(temperature: 1.0, topP: 1.0, maxTokens: 3)

        let generator = LLMGenerator(model: model, tokenizer: tokenizer, parameters: params)

        let promptTokens = tokenizer.encode(text: "xyz")
        var tokenCount = 0

        for await _ in generator.generate(prompt: promptTokens) {
            tokenCount += 1
        }

        XCTAssertLessThanOrEqual(tokenCount, params.maxTokens)
    }

    func testGeneration_cancellation() async throws {
        let model = MockLLMModel()
        let tokenizer = MockTokenizer()
        let params = GenerationParameters(temperature: 1.0, topP: 1.0, maxTokens: 1000)

        let generator = LLMGenerator(model: model, tokenizer: tokenizer, parameters: params)
        let promptTokens = tokenizer.encode(text: "long prompt")

        let expectation = expectation(description: "Stream cancelled early")

        let task = Task {
            var count = 0
            for await _ in generator.generate(prompt: promptTokens) {
                count += 1
                if count == 5 {
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
