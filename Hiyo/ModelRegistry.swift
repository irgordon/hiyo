import Foundation

final class MLXModelRegistry {
    let defaultModels: [MLXModel] = [
        MLXModel(
            id: "mlx-community/Llama-3.2-3B-Instruct-4bit",
            name: "Llama 3.2 3B",
            description: "Fast and efficient for everyday tasks",
            size: "1.9 GB",
            parameters: "3B"
        ),
        MLXModel(
            id: "mlx-community/Llama-3.2-1B-Instruct-4bit",
            name: "Llama 3.2 1B",
            description: "Ultra-fast, minimal memory usage",
            size: "0.7 GB",
            parameters: "1B"
        ),
        MLXModel(
            id: "mlx-community/Mistral-7B-Instruct-v0.3-4bit",
            name: "Mistral 7B",
            description: "High quality reasoning and coding",
            size: "4.1 GB",
            parameters: "7B"
        ),
        MLXModel(
            id: "mlx-community/Phi-3-mini-4k-instruct-4bit",
            name: "Phi-3 Mini",
            description: "Microsoft's efficient small model",
            size: "1.8 GB",
            parameters: "3.8B"
        ),
        MLXModel(
            id: "mlx-community/Qwen2.5-7B-Instruct-4bit",
            name: "Qwen 2.5 7B",
            description: "Strong multilingual capabilities",
            size: "4.2 GB",
            parameters: "7B"
        ),
        MLXModel(
            id: "mlx-community/CodeLlama-7B-Instruct-4bit",
            name: "CodeLlama 7B",
            description: "Optimized for code generation",
            size: "4.1 GB",
            parameters: "7B"
        )
    ]
    
    func getModel(_ id: String) -> MLXModel? {
        defaultModels.first { $0.id == id }
    }
}
