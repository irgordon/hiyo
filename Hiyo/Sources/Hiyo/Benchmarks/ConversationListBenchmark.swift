//
//  ConversationListBenchmark.swift
//  Hiyo
//
//  Benchmark to measure N+1 query impact on conversation list rendering.
//

import Foundation
import SwiftData

@MainActor
final class ConversationListBenchmark {
    static func run(chatCount: Int = 100, messagesPerChat: Int = 50) async throws {
        print("📊 Starting ConversationListBenchmark with \(chatCount) chats, \(messagesPerChat) messages each...")

        // 1. Setup
        let schema = Schema([Chat.self, Message.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        // 2. Seed Data
        print("🌱 Seeding data...")
        let seedStart = Date()

        for i in 0..<chatCount {
            let chat = Chat(title: "Chat \(i)", modelIdentifier: "model-v1")
            for j in 0..<messagesPerChat {
                let msg = Message(content: "Message \(j) content which is long enough to be interesting.", role: j % 2 == 0 ? .user : .assistant)
                chat.messages.append(msg)
            }
            context.insert(chat)
        }
        try context.save()

        let seedDuration = Date().timeIntervalSince(seedStart)
        print("   Seeding took \(String(format: "%.3f", seedDuration))s")

        // 3. Measure N+1 Access (Baseline)
        print("⏱️  Measuring N+1 Access (Baseline)...")

        // Fetch chats without prefetching messages
        let descriptor = FetchDescriptor<Chat>(sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)])
        let chats = try context.fetch(descriptor)

        let baselineStart = Date()

        var totalPreviewLength = 0
        var totalMessages = 0

        for chat in chats {
            // Simulate View Access: accessing last message and count
            // This triggers lazy loading of the relationship
            let preview = chat.messages.last?.content ?? "No messages"
            let count = chat.messages.count

            totalPreviewLength += preview.count
            totalMessages += count
        }

        let baselineDuration = Date().timeIntervalSince(baselineStart)
        print("✅ Baseline (N+1 Access) completed in \(String(format: "%.4f", baselineDuration))s")
        print("   Processed \(totalMessages) messages total")

        // 4. Measure Denormalized Access (Simulated Optimized)
        // Since we haven't implemented the fields yet, we'll simulate accessing a direct property
        // by accessing the title (which is already loaded) and assuming O(1) access.

        print("⏱️  Measuring Denormalized Access (Simulated Optimized)...")
        let optimizedStart = Date()

        var totalTitleLength = 0
        var totalSimulatedCount = 0

        for chat in chats {
            // Simulate accessing denormalized fields
            // In the real optimization, we'd access chat.lastMessagePreview and chat.messageCountCache
            let preview = chat.title // Placeholder for lastMessagePreview
            let count = 50 // Placeholder for messageCountCache

            totalTitleLength += preview.count
            totalSimulatedCount += count
        }

        let optimizedDuration = Date().timeIntervalSince(optimizedStart)
        print("✅ Optimized (Simulated) completed in \(String(format: "%.4f", optimizedDuration))s")

        let improvement = baselineDuration / optimizedDuration
        print("🚀 Projected Speedup: \(String(format: "%.1fx", improvement))")
    }
}
