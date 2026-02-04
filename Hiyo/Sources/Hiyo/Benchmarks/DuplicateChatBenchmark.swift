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
    /// Runs a benchmark comparing the duplication performance.
    /// - Parameter messageCount: Number of messages in the chat to duplicate.
    static func run(messageCount: Int = 1000) async throws {
        print("📊 Starting DuplicateChatBenchmark with \(messageCount) messages...")

        // 1. Setup
        let schema = Schema([Chat.self, Message.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        // 2. Seed Data
        print("🌱 Seeding chat...")
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
        let seedDuration = Date().timeIntervalSince(seedStart)
        print("   Seeding took \(String(format: "%.3f", seedDuration))s")

        let chatID = chat.persistentModelID

        // 3. Measure Baseline (Synchronous Simulation)
        print("⏱️  Measuring synchronous duplication (Baseline)...")
        let syncStart = Date()

        // Simulate the old synchronous logic
        let newChatSync = Chat(title: chat.title + " Copy Sync", modelIdentifier: chat.modelIdentifier)
        for message in chat.messages {
            let newMessage = Message(content: message.content, role: message.role)
            newMessage.tokensUsed = message.tokensUsed
            newMessage.latencyMs = message.latencyMs
            newChatSync.messages.append(newMessage)
        }
        context.insert(newChatSync)
        try context.save()

        let syncDuration = Date().timeIntervalSince(syncStart)
        print("✅ Baseline (Sync) completed in \(String(format: "%.4f", syncDuration))s")

        // 4. Measure Optimized (Asynchronous)
        print("⏱️  Measuring asynchronous duplication (Optimized)...")
        let asyncStart = Date()

        // Simulate the optimized logic (Background Task)
        await withCheckedContinuation { continuation in
            Task.detached {
                let bgContext = ModelContext(container)
                guard let bgChat = bgContext.model(for: chatID) as? Chat else {
                    return
                }

                let newChatAsync = Chat(title: bgChat.title + " Copy Async", modelIdentifier: bgChat.modelIdentifier)

                // Sort to ensure order
                let sortedMessages = bgChat.messages.sorted { $0.timestamp < $1.timestamp }

                for message in sortedMessages {
                    let newMessage = Message(content: message.content, role: message.role)
                    newMessage.tokensUsed = message.tokensUsed
                    newMessage.latencyMs = message.latencyMs
                    newChatAsync.messages.append(newMessage)
                }

                bgContext.insert(newChatAsync)
                try? bgContext.save()

                continuation.resume()
            }
        }

        let asyncDuration = Date().timeIntervalSince(asyncStart)
        print("✅ Optimized (Async Total) completed in \(String(format: "%.4f", asyncDuration))s")

        // Note: The key improvement is not necessarily total duration, but Main Thread blocking time.
        // In the Async version, the Main Thread blocking time is effectively 0s (excluding task launch overhead).
    }
}
