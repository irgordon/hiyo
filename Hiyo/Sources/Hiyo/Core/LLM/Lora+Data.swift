// Copyright © 2024 Apple Inc.

import Foundation

enum LoRADataError: Error {
    case fileNotFound(URL, String)
}

/// Load a LoRA data file.
///
/// Given a directory and a base name, e.g. `train`, this will load a `.jsonl` or `.txt` file
/// if possible.
public func loadLoRAData(directory: URL, name: String) throws -> [String] {
    let extensions = ["jsonl", "txt"]

    for ext in extensions {
        let url = directory.appending(component: "\(name).\(ext)")
        if FileManager.default.fileExists(atPath: url.path()) {
            return try loadLoRAData(url: url)
        }
    }

    throw LoRADataError.fileNotFound(directory, name)
}

/// Load a .txt or .jsonl file and return the contents
public func loadLoRAData(url: URL) throws -> [String] {
    switch url.pathExtension {
    case "jsonl":
        return try loadJSONL(url: url)

    case "txt":
        return try loadLines(url: url)

    default:
        fatalError("Unable to load data file, unknown type: \(url)")

    }
}

func loadJSONL(url: URL) throws -> [String] {

    struct Line: Codable {
        let text: String?
    }

    let decoder = JSONDecoder()
    var lines = [String]()
    var failure: Error?

    try String(contentsOf: url).enumerateLines { line, stop in
        guard line.first == "{" else { return }

        // Note: We use ! here to match original behavior, assuming valid UTF8 from String
        let data = line.data(using: .utf8)!

        do {
            if let text = try decoder.decode(Line.self, from: data).text {
                lines.append(text)
            }
        } catch {
            failure = error
            stop = true
        }
    }

    if let failure {
        throw failure
    }

    return lines
}

func loadLines(url: URL) throws -> [String] {
    var lines = [String]()
    try String(contentsOf: url).enumerateLines { line, _ in
        if !line.isEmpty {
            lines.append(line)
        }
    }
    return lines
}
