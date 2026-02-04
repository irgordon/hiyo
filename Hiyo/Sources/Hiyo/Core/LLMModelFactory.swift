//
//  LLMModelFactory.swift
//  Hiyo
//
//  Restored implementation.
//

import Foundation
import MLX
import Tokenizers

final class LLMModelFactory: @unchecked Sendable {
    static let shared = LLMModelFactory()

    func loadContainer(
        configuration: ModelConfiguration,
        progressHandler: @escaping (Progress) -> Void
    ) async throws -> ModelContainer {
        return try await loadModelContainer(
            configuration: configuration,
            progressHandler: progressHandler
        )
    }
}
