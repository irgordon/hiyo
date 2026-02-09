//
//  MessageTimestampBenchmark.swift
//  Hiyo
//
//  Benchmark for measuring performance of Message.formattedTimestamp.
//

import Foundation
import SwiftData

final class MessageTimestampBenchmark {

    /// Runs a benchmark for Message.formattedTimestamp.
    /// - Parameter iterations: Number of formatting operations to perform.
    @MainActor
    static func run(iterations: Int = 10000) {
        print("📊 Starting MessageTimestampBenchmark with \(iterations) iterations...")

        // Create a message instance
        // Note: Creating a SwiftData model without a container is generally fine for unit tests/benchmarks
        // as long as we don't try to save it or access relationships that lazy load.
        // However, to be safe and avoid context errors, we'll try to keep it simple.
        let message = Message(content: "Test content", role: .user)

        print("⏱️  Measuring Message.formattedTimestamp...")
        let start = Date()

        for _ in 0..<iterations {
            let _ = message.formattedTimestamp(style: .short)
        }

        let duration = Date().timeIntervalSince(start)
        print("✅ Duration: \(String(format: "%.6f", duration))s")
        print("ℹ️  Average per call: \(String(format: "%.9f", duration / Double(iterations)))s")
    }
}
