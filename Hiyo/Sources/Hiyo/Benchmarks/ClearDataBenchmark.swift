//
//  ClearDataBenchmark.swift
//  Hiyo
//
//  Benchmark for measuring performance of data clearing operations.
//

import Foundation
import SwiftData

@MainActor
final class ClearDataBenchmark {
    /// Runs a benchmark comparing the deletion performance.
    /// - Parameter chatCount: Number of chats to generate for the test.
    static func run(chatCount: Int = 1000) throws {
        print("📊 Starting ClearDataBenchmark with \(chatCount) items...")

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
                let msg = Message(content: "Message content \(j)", role: j % 2 == 0 ? .user : .assistant)
                chat.messages.append(msg)
            }
            context.insert(chat)
        }
        try context.save()
        let seedDuration = Date().timeIntervalSince(seedStart)
        print("   Seeding took \(String(format: "%.3f", seedDuration))s")

        // Verify seeding
        let fetchDescriptor = FetchDescriptor<Chat>()
        let initialCount = try context.fetchCount(fetchDescriptor)
        print("   Verifying seed: \(initialCount) chats present.")

        // 3. Measure Deletion
        print("⏱️  Measuring deletion...")
        let deleteStart = Date()

        // The optimization target:
        try context.delete(model: Chat.self)
        try context.save()

        let deleteDuration = Date().timeIntervalSince(deleteStart)
        print("✅ Deletion completed in \(String(format: "%.4f", deleteDuration))s")
        print("   Rate: \(Int(Double(chatCount) / deleteDuration)) chats/sec")

        // 4. Verify Empty
        let remainingCount = try context.fetchCount(fetchDescriptor)
        if remainingCount == 0 {
            print("🎉 Verification Successful: Database is empty.")
        } else {
            print("❌ Verification Failed: \(remainingCount) items remain.")
        }
    }
}
