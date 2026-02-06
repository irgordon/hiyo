
import XCTest
@testable import Hiyo

final class LoRABenchmarkTests: XCTestCase {

    func testLoadJSONLPerformance() throws {
        // Create a temporary file with JSONL data
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let fileURL = temporaryDirectory.appendingPathComponent("benchmark_\(UUID().uuidString).jsonl")

        let lineCount = 10_000
        var content = ""
        for i in 0..<lineCount {
            content += "{\"text\": \"This is line \(i) of the benchmark data.\"}\n"
        }
        // Add some noise/invalid lines to test filter
        content += "Invalid line 1\n"
        content += "Invalid line 2\n"

        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        defer {
            try? FileManager.default.removeItem(at: fileURL)
        }

        // Measure performance
        measure {
            do {
                _ = try loadJSONL(url: fileURL)
            } catch {
                XCTFail("Failed to load JSONL: \(error)")
            }
        }
    }
}
