//
//  BenchmarkTests.swift
//  HiyoTests
//
//  Tests to run performance benchmarks.
//

import XCTest
@testable import Hiyo

final class BenchmarkTests: XCTestCase {

    @MainActor
    func testExportBenchmark() throws {
        // Run the benchmark
        // Reducing count slightly to keep test fast, but high enough to measure
        try ExportBenchmark.run(chatCount: 20, messagesPerChat: 50)
    }

    @MainActor
    func testExportComparison() async throws {
        // Run the comparison benchmark
        try await ExportComparison.run(chatCount: 50, messagesPerChat: 200)
    }

    func testDateFormatterBenchmark() {
        // Run the date formatter benchmark
        DateFormatterBenchmark.run(iterations: 100_000)
    }

    @MainActor
    func testMessageTimestampBenchmark() {
        // Run the message timestamp benchmark
        MessageTimestampBenchmark.run(iterations: 10_000)
    }
}
