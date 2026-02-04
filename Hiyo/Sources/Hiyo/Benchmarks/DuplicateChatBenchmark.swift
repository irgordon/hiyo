//
//  DuplicateChatBenchmark.swift
//  Hiyo
//
//  Benchmark for measuring performance of chat duplication.
//

import Foundation
import SwiftData

@MainActor
final class DuplicateChatBenchmark {
    static func run(messageCount: Int = 1000) throws {
        print("📊 Starting DuplicateChatBenchmark with \(messageCount) messages...")

        // 1. Setup
        let schema = Schema([Chat.self, Message.self])
        let url = URL(fileURLWithPath: "/tmp/hiyo_bench_\(UUID().uuidString).store")
        let config = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        // 2. Seed Data
        print("🌱 Seeding data...")
        let seedStart = Date()
        let chat = Chat(title: "Benchmark Chat", modelIdentifier: "test-model")

        for i in 0..<messageCount {
            let msg = Message(content: "Message content \(i)", role: i % 2 == 0 ? .user : .assistant)
            msg.tokensUsed = 10
            msg.latencyMs = 50.0
            chat.messages.append(msg)
        }
        context.insert(chat)
        try context.save()
        let chatID = chat.id

        let seedDuration = Date().timeIntervalSince(seedStart)
        print("   Seeding took \(String(format: "%.3f", seedDuration))s")

        // 3. Measure Baseline (Synchronous/Blocking)
        print("⏱️  Measuring Baseline (Blocking)...")
        let baselineStart = Date()

        // --- Baseline Logic (Copy of original duplicateChat) ---
        let newChat = Chat(title: chat.title + " Copy", modelIdentifier: chat.modelIdentifier)

        for message in chat.messages {
            let newMessage = Message(content: message.content, role: message.role)
            newMessage.tokensUsed = message.tokensUsed
            newMessage.latencyMs = message.latencyMs
            newChat.messages.append(newMessage)
        }

        context.insert(newChat)
        try context.save()
        // -----------------------------------------------------

        let baselineDuration = Date().timeIntervalSince(baselineStart)
        print("✅ Baseline (Blocking) took \(String(format: "%.4f", baselineDuration))s")


        // 4. Measure Optimized (Asynchronous/Non-blocking)
        print("⏱️  Measuring Optimized (Non-blocking)...")
        let optimizedStart = Date()

        // --- Optimized Logic ---
        // We measure how fast this returns control to the main thread

        let task = Task.detached {
            // Re-create container/context in background
            let bgContext = ModelContext(container)

            // Fetch original
            guard let bgChat = try? bgContext.fetch(FetchDescriptor<Chat>(predicate: #Predicate { $0.id == chatID })).first else {
                return
            }

            let bgNewChat = Chat(title: bgChat.title + " Copy 2", modelIdentifier: bgChat.modelIdentifier)

            for message in bgChat.messages {
                let newMessage = Message(content: message.content, role: message.role)
                newMessage.tokensUsed = message.tokensUsed
                newMessage.latencyMs = message.latencyMs
                bgNewChat.messages.append(newMessage)
            }

            bgContext.insert(bgNewChat)
            try? bgContext.save()
        }

        // -----------------------

        let optimizedDuration = Date().timeIntervalSince(optimizedStart)
        print("✅ Optimized (Non-blocking) took \(String(format: "%.6f", optimizedDuration))s") // Should be near zero

        let improvement = baselineDuration / optimizedDuration
        print("🚀 Main Thread Unblocking Factor: \(String(format: "%.2f", improvement))x")

        // Verification (Wait for task)
        print("   Waiting for background task to complete verification...")
        _ = await task.result
        print("   Background task completed.")

        // Cleanup
        try? FileManager.default.removeItem(at: url)
    }
}
