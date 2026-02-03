//
//  TokenGenerationBenchmark.swift
//  Hiyo
//
//  Benchmark for measuring performance of token generation persistence strategies.
//

import Foundation
import SwiftData

@MainActor
final class TokenGenerationBenchmark {
    /// Runs a benchmark comparing N+1 save vs Single save.
    /// - Parameter tokenCount: Number of tokens to simulate.
    static func run(tokenCount: Int = 100) throws {
        print("📊 Starting TokenGenerationBenchmark with \(tokenCount) tokens...")

        // 1. Setup
        let schema = Schema([Chat.self, Message.self])
        // Use disk storage to measure I/O impact
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        // Create a temporary container
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        // Create a chat for the test
        let chat = Chat(title: "Benchmark Chat", modelIdentifier: "test-model")
        context.insert(chat)
        try context.save()

        // 2. Measure N+1 Save (Baseline)
        print("⏱️  Measuring N+1 Save (Baseline)...")
        let baselineMessage = Message(content: "", role: .assistant)
        chat.messages.append(baselineMessage)

        let baselineStart = Date()
        for i in 0..<tokenCount {
            baselineMessage.content += "token"
            // Simulate the overhead of saving on every token
            try context.save()
            // In a real stream, there's a slight delay, but we want to measure the overhead.
        }
        let baselineDuration = Date().timeIntervalSince(baselineStart)
        print("✅ N+1 Save completed in \(String(format: "%.4f", baselineDuration))s")

        // 3. Measure Single Save (Optimized)
        print("⏱️  Measuring Single Save (Optimized)...")
        let optimizedMessage = Message(content: "", role: .assistant)
        chat.messages.append(optimizedMessage)

        let optimizedStart = Date()
        for i in 0..<tokenCount {
            optimizedMessage.content += "token"
        }
        // Save once at the end
        try context.save()
        let optimizedDuration = Date().timeIntervalSince(optimizedStart)
        print("✅ Single Save completed in \(String(format: "%.4f", optimizedDuration))s")

        // 4. Results
        let improvement = baselineDuration / optimizedDuration
        print("🚀 Speedup: \(String(format: "%.2f", improvement))x")

        // Cleanup (best effort)
        try? context.delete(model: Chat.self)
        try? context.save()
    }
}
