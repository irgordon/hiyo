//
//  ExportBenchmark.swift
//  Hiyo
//
//  Benchmark for measuring performance of chat export operations.
//

import Foundation
import SwiftData
import CryptoKit

@MainActor
final class ExportBenchmark {
    /// Runs a benchmark for exporting chats.
    /// - Parameter chatCount: Number of chats to simulate.
    /// - Parameter messagesPerChat: Number of messages per chat.
    static func run(chatCount: Int = 50, messagesPerChat: Int = 100) throws {
        print("📊 Starting ExportBenchmark with \(chatCount) chats, \(messagesPerChat) messages each...")

        // 1. Setup
        let schema = Schema([Chat.self, Message.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        var chats: [Chat] = []

        print("🛠️  Generating data...")
        for i in 0..<chatCount {
            let chat = Chat(title: "Benchmark Chat \(i)", modelIdentifier: "test-model")
            chat.createdAt = Date().addingTimeInterval(Double(-i * 3600))
            chat.modifiedAt = Date()

            for j in 0..<messagesPerChat {
                let msg = Message(content: "This is a benchmark message content used to simulate data volume. Index: \(j)", role: j % 2 == 0 ? .user : .assistant)
                msg.tokensUsed = 10
                msg.timestamp = chat.createdAt.addingTimeInterval(Double(j * 60))
                chat.messages.append(msg)
            }
            context.insert(chat)
            chats.append(chat)
        }
        try context.save()

        // 2. Encryption Key Generation
        let key = SymmetricKey(size: .bits256)

        // 3. Measure Encoding and Encryption (Blocking)
        print("⏱️  Measuring synchronous export (Encoding + Encryption)...")
        let start = Date()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        // Encode
        let data = try encoder.encode(chats)

        // Encrypt
        let sealedBox = try AES.GCM.seal(data, using: key)
        let _ = sealedBox.combined

        let duration = Date().timeIntervalSince(start)
        print("✅ Export operation: \(String(format: "%.6f", duration))s")
        print("📦 Data size: \(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))")
    }
}
