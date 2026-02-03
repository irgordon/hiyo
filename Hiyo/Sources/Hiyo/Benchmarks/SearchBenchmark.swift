//
//  SearchBenchmark.swift
//  Hiyo
//
//  Benchmark for measuring performance of search operations.
//

import Foundation
import SwiftData

@MainActor
final class SearchBenchmark {
    /// Runs a benchmark comparing the search performance.
    /// - Parameter chatCount: Number of chats to generate for the test.
    static func run(chatCount: Int = 1000) throws {
        print("📊 Starting SearchBenchmark with \(chatCount) items...")

        // 1. Setup
        let schema = Schema([Chat.self, Message.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        // 2. Seed Data
        print("🌱 Seeding data...")
        let seedStart = Date()
        for i in 0..<chatCount {
            let chat = Chat(title: "Benchmark Chat \(i)", modelIdentifier: "test-model")
            // Add some messages to make it realistic
            for j in 0..<5 {
                let content = (i % 10 == 0 && j == 2) ? "UniqueKeyword" : "Message content \(j)"
                let msg = Message(content: content, role: j % 2 == 0 ? .user : .assistant)
                chat.messages.append(msg)
            }
            context.insert(chat)
        }
        try context.save()
        let seedDuration = Date().timeIntervalSince(seedStart)
        print("   Seeding took \(String(format: "%.3f", seedDuration))s")

        let searchText = "UniqueKeyword"

        // 3. Measure In-Memory Filtering (Baseline)
        print("⏱️  Measuring In-Memory Filtering (N+1)...")
        let baselineStart = Date()

        let descriptor = FetchDescriptor<Chat>()
        let allChats = try context.fetch(descriptor)
        let filteredChats = allChats.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.messages.contains { $0.content.localizedCaseInsensitiveContains(searchText) }
        }

        let baselineDuration = Date().timeIntervalSince(baselineStart)
        print("✅ In-Memory Filtering completed in \(String(format: "%.4f", baselineDuration))s")
        print("   Found \(filteredChats.count) matches.")

        // 4. Measure Predicate Filtering (Optimized)
        print("⏱️  Measuring Predicate Filtering...")
        let optimizedStart = Date()

        // Note: localizedCaseInsensitiveContains might not be supported in all Predicate contexts yet depending on Swift version,
        // but standard contains is often optimized. For the sake of this benchmark we assume standard availability.
        // SwiftData predicates are translated to SQL/Store queries.

        let predicate = #Predicate<Chat> { chat in
            chat.title.localizedStandardContains(searchText) ||
            chat.messages.contains { message in
                message.content.localizedStandardContains(searchText)
            }
        }

        let optimizedDescriptor = FetchDescriptor<Chat>(predicate: predicate)
        let optimizedResults = try context.fetch(optimizedDescriptor)

        let optimizedDuration = Date().timeIntervalSince(optimizedStart)
        print("✅ Predicate Filtering completed in \(String(format: "%.4f", optimizedDuration))s")
        print("   Found \(optimizedResults.count) matches.")

        let improvement = baselineDuration / optimizedDuration
        print("🚀 Speedup: \(String(format: "%.2f", improvement))x")
    }
}
