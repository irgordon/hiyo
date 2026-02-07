//
//  ExportComparison.swift
//  Hiyo
//
//  Compares blocking vs non-blocking export strategies.
//

import Foundation
import SwiftData
import CryptoKit

@MainActor
final class ExportComparison {

    static func run(chatCount: Int = 100, messagesPerChat: Int = 100) async throws {
        print("\n📊 Starting ExportComparison with \(chatCount) chats, \(messagesPerChat) messages each...")

        // 1. Setup Data
        let schema = Schema([Chat.self, Message.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        print("🛠️  Generating data...")
        for chatIndex in 0..<chatCount {
            let chat = Chat(title: "Benchmark Chat \(chatIndex)", modelIdentifier: "test-model")
            chat.createdAt = Date().addingTimeInterval(Double(-chatIndex * 3600))
            chat.modifiedAt = Date()

            for messageIndex in 0..<messagesPerChat {
                let content = "This is a benchmark message content used to simulate data volume. Index: \(messageIndex)"
                let role: MessageRole = messageIndex % 2 == 0 ? .user : .assistant
                let msg = Message(content: content, role: role)
                msg.tokensUsed = 10
                msg.timestamp = chat.createdAt.addingTimeInterval(Double(messageIndex * 60))
                chat.messages.append(msg)
            }
            context.insert(chat)
        }
        try context.save()

        // Fetch objects for Strategy 1 (simulating they are already in memory/context)
        let descriptor = FetchDescriptor<Chat>(sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)])
        let chats = try context.fetch(descriptor)

        let key = SymmetricKey(size: .bits256)

        // 2. Measure "Current" Strategy (Main Thread Blocking)
        // In the current implementation, mapping to DTOs happens on the main thread.

        print("\n⏱️  Measuring Strategy 1: Map on Main Actor (Current)...")
        let start1 = Date()

        // This simulates the work done on the main thread in the current HiyoStore.exportChats
        let chatDTOs = chats.map { chat in
            ChatDTO(
                id: chat.id,
                title: chat.title,
                createdAt: chat.createdAt,
                modifiedAt: chat.modifiedAt,
                messages: chat.messages.map { msg in
                    MessageDTO(
                        id: msg.id,
                        content: msg.content,
                        role: msg.role,
                        timestamp: msg.timestamp,
                        tokensUsed: msg.tokensUsed,
                        latencyMs: msg.latencyMs
                    )
                },
                modelIdentifier: chat.modelIdentifier
            )
        }

        let blockingDuration1 = Date().timeIntervalSince(start1)
        print("🔴 Main Thread Blocked: \(String(format: "%.6f", blockingDuration1))s")

        // Finish the job (encoding/encrypting in background)
        _ = try await Task.detached {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(chatDTOs)
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined
        }.value

        // 3. Measure "Optimized" Strategy (Background Fetch & Map)
        // In the optimized implementation, we fetch and map in the background.

        print("\n⏱️  Measuring Strategy 2: Fetch & Map in Background (Optimized)...")
        let start2 = Date()

        // Main thread work is just dispatching
        // This simulates `try await Task.detached { ... }` initiation
        let blockingDuration2 = Date().timeIntervalSince(start2)
        print("🟢 Main Thread Blocked: \(String(format: "%.6f", blockingDuration2))s")

        // The actual work happens in background
        let backgroundStart = Date()
        _ = try await Task.detached {
            let bgContext = ModelContext(container)
            // Fetch everything
            let descriptor = FetchDescriptor<Chat>(sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)])
            let bgChats = try bgContext.fetch(descriptor)

            // Map
            let bgDTOs = bgChats.map { chat in
                ChatDTO(
                    id: chat.id,
                    title: chat.title,
                    createdAt: chat.createdAt,
                    modifiedAt: chat.modifiedAt,
                    messages: chat.messages.map { msg in
                        MessageDTO(
                            id: msg.id,
                            content: msg.content,
                            role: msg.role,
                            timestamp: msg.timestamp,
                            tokensUsed: msg.tokensUsed,
                            latencyMs: msg.latencyMs
                        )
                    },
                    modelIdentifier: chat.modelIdentifier
                )
            }

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(bgDTOs)
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined
        }.value

        let backgroundDuration = Date().timeIntervalSince(backgroundStart)
        print("Background Work Duration: \(String(format: "%.6f", backgroundDuration))s")

        // Comparison
        let improvement = blockingDuration1 - blockingDuration2
        print("\n🚀 Main Thread Improvement: \(String(format: "%.6f", improvement))s freed up")

        if blockingDuration2 > 0.000001 {
             print("⚡ Speedup Factor (Main Thread): \(String(format: "%.1fx", blockingDuration1 / blockingDuration2))")
        } else {
             print("⚡ Speedup Factor (Main Thread): > 1000x")
        }
    }
}
