//
//  LoadModelOperation.swift
//  Hiyo
//
//  Encapsulates model loading operations in a dedicated actor.
//

import Foundation

actor LoadModelOperation {
    func load(
        configuration: ModelConfiguration,
        progressHandler: @Sendable @escaping (Progress) -> Void
    ) async throws -> ModelContainer {
        return try await LLMModelFactory.shared.loadContainer(
            configuration: configuration,
            progressHandler: progressHandler
        )
    }
}
