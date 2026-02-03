//
//  MLXModelRegistry.swift
//  Hiyo
//
//  Curated list of recommended MLX models.
//

import Foundation

struct MLXModel: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let size: String
    let parameters: String
    let tags: [String]
}

final class MLXModelRegistry {
    let defaultModels: [MLXModel] = [
        MLXModel(
            id: "mlx-community/Llama-3.2-1B-Instruct-4bit",
            name: "Llama 3.2 1B",
            description: "Ultra-fast, minimal memory usage. Great for quick tasks.",
            size: "0.7 GB",
            parameters: "1B",
            tags: ["fast", "efficient", "beginner"]
        ),
        MLXModel(
            id: "mlx-community/Llama-3.2-3B-Instruct-4bit",
            name: "Llama 3.2 3B",
            description: "Fast and capable. Best balance of speed and quality.",
            size: "1.9 GB",
            parameters: "3B",
            tags: ["recommended", "balanced", "general"]
        ),
        MLXModel(
            id: "mlx-community/Mistral-7B-Instruct-v0.3-4bit",
            name: "Mistral 7B",
            description: "High quality reasoning and instruction following.",
            size: "4.1 GB",
            parameters: "7B",
            tags: ["advanced", "reasoning", "powerful"]
        ),
        MLXModel(
            id: "mlx-community/Phi-3-mini-4k-instruct-4bit",
            name: "Phi-3 Mini",
            description: "Microsoft's efficient small model. Strong performance.",
            size: "1.8 GB",
            parameters: "3.8B",
            tags: ["efficient", "microsoft", "quality"]
        ),
        MLXModel(
            id: "mlx-community/Qwen2.5-7B-Instruct-4bit",
            name: "Qwen 2.5 7B",
            description: "Strong multilingual capabilities and coding.",
            size: "4.2 GB",
            parameters: "7B",
            tags: ["multilingual", "coding", "advanced"]
        ),
        MLXModel(
            id: "mlx-community/CodeLlama-7B-Instruct-4bit",
            name: "CodeLlama 7B",
            description: "Optimized for code generation and technical tasks.",
            size: "4.1 GB",
            parameters: "7B",
            tags: ["coding", "technical", "developer"]
        )
    ]
    
    func getModel(_ id: String) -> MLXModel? {
        defaultModels.first { $0.id == id }
    }
    
    func models(tagged tag: String) -> [MLXModel] {
        defaultModels.filter { $0.tags.contains(tag) }
    }
}
