//
//  ChatPerformanceBenchmark.swift
//  Hiyo
//
//  Benchmark for measuring performance of Chat computed properties.
//

import Foundation
import SwiftData

@MainActor
final class ChatPerformanceBenchmark {
    /// Runs a benchmark accessing totalTokens and lastMessage.
    /// - Parameter messageCount: Number of messages to simulate.
    static func run(messageCount: Int = 5000) throws {
        print("📊 Starting ChatPerformanceBenchmark with \(messageCount) messages...")

        // 1. Setup
        let schema = Schema([Chat.self, Message.self])
        // In-memory to focus on property access CPU time, not disk I/O
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let chat = Chat(title: "Benchmark Chat", modelIdentifier: "test-model")

        // Add messages
        for i in 0..<messageCount {
            let msg = Message(content: "Message \(i)", role: .user)
            msg.tokensUsed = 10
            // Shuffle timestamps slightly to force sort to do work if it relies on timestamp
            msg.timestamp = Date().addingTimeInterval(Double(i))
            chat.messages.append(msg)
        }
        context.insert(chat)
        try context.save()

        // 2. Measure totalTokens
        print("⏱️  Measuring totalTokens access...")
        let tokensStart = Date()
        let _ = chat.totalTokens
        let tokensDuration = Date().timeIntervalSince(tokensStart)
        print("✅ totalTokens access: \(String(format: "%.6f", tokensDuration))s")

        // 3. Measure lastMessage
        print("⏱️  Measuring lastMessage access...")
        let lastMsgStart = Date()
        let _ = chat.lastMessage
        let lastMsgDuration = Date().timeIntervalSince(lastMsgStart)
        print("✅ lastMessage access: \(String(format: "%.6f", lastMsgDuration))s")

        // 4. Measure multiple accesses (simulating a list view scroll or update)
        print("⏱️  Measuring 100x accesses...")
        let loopStart = Date()
        for _ in 0..<100 {
            let _ = chat.totalTokens
            let _ = chat.lastMessage
        }
        let loopDuration = Date().timeIntervalSince(loopStart)
        print("✅ 100x loop: \(String(format: "%.6f", loopDuration))s")
    }
}
