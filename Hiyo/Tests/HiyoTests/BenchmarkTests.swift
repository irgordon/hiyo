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
}
