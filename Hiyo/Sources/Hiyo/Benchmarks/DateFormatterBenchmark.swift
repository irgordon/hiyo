//
//  DateFormatterBenchmark.swift
//  Hiyo
//
//  Benchmark for measuring performance of date formatting operations.
//

import Foundation

final class DateFormatterBenchmark {

    /// Runs a benchmark comparing new formatter allocation vs static reuse.
    /// - Parameter iterations: Number of formatting operations to perform.
    static func run(iterations: Int = 10000) {
        print("📊 Starting DateFormatterBenchmark with \(iterations) iterations...")

        let date = Date()

        // 1. Measure Baseline (New Instance per call)
        print("⏱️  Measuring baseline (New Instance)...")
        let startBaseline = Date()

        for _ in 0..<iterations {
            let _ = ISO8601DateFormatter().string(from: date)
        }

        let durationBaseline = Date().timeIntervalSince(startBaseline)
        print("✅ Baseline (New Instance): \(String(format: "%.6f", durationBaseline))s")

        // 2. Measure Optimized (Static Instance)
        print("⏱️  Measuring optimized (Static Instance)...")
        let staticFormatter = ISO8601DateFormatter()
        let startOptimized = Date()

        for _ in 0..<iterations {
            let _ = staticFormatter.string(from: date)
        }

        let durationOptimized = Date().timeIntervalSince(startOptimized)
        print("✅ Optimized (Static Instance): \(String(format: "%.6f", durationOptimized))s")

        let improvement = (durationBaseline - durationOptimized) / durationBaseline * 100
        print("🚀 Improvement: \(String(format: "%.2f", improvement))%")
    }
}
