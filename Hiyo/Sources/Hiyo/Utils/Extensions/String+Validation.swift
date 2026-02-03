//
//  String+Validation.swift
//  Hiyo
//
//  String extension methods for validation and sanitization.
//

import Foundation

extension String {
    /// Trims whitespace and newlines
    var trimmed: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Checks if string is empty after trimming
    var isBlank: Bool {
        self.trimmed.isEmpty
    }
    
    /// Truncates string to specified length with ellipsis
    func truncated(to length: Int, addEllipsis: Bool = true) -> String {
        if self.count <= length {
            return self
        }
        
        let truncated = String(self.prefix(length))
        return addEllipsis ? truncated + "..." : truncated
    }
    
    /// Removes all control characters except newlines and tabs
    var removingControlCharacters: String {
        self.unicodeScalars.filter { scalar in
            switch scalar.value {
            case 0x00...0x08, 0x0B...0x1F, 0x7F...0x9F:
                return false
            default:
                return true
            }
        }.map { String($0) }.joined()
    }
    
    /// Normalizes line endings to Unix style
    var normalizingLineEndings: String {
        self.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
    }
    
    /// Counts tokens (rough estimate based on whitespace and punctuation)
    var estimatedTokenCount: Int {
        // Rough estimate: ~4 characters per token for English
        max(1, self.count / 4)
    }
    
    /// Validates as a safe filename
    var isSafeFilename: Bool {
        let invalidCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>")
        return self.rangeOfCharacter(from: invalidCharacters) == nil
            && !self.hasPrefix(".")
            && !self.isEmpty
            && self.count < 255
    }
    
    /// Sanitizes for use as a filename
    var sanitizedFilename: String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>")
        var sanitized = self.components(separatedBy: invalidCharacters).joined(separator: "_")
        
        // Remove leading dots
        while sanitized.hasPrefix(".") {
            sanitized.removeFirst()
        }
        
        // Truncate if too long
        if sanitized.count > 200 {
            sanitized = String(sanitized.prefix(200))
        }
        
        // Ensure not empty
        if sanitized.isEmpty {
            sanitized = "untitled"
        }
        
        return sanitized
    }
    
    /// Checks if string looks like a URL
    var isValidURL: Bool {
        guard let url = URL(string: self) else { return false }
        return url.scheme != nil && url.host != nil
    }
    
    /// Extracts markdown code blocks
    var codeBlocks: [(language: String?, code: String)] {
        let pattern = #"```(?:([a-zA-Z0-9]+)\n)?([\s\S]*?)```"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }
        
        let matches = regex.matches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count))
        
        return matches.compactMap { match in
            let languageRange = match.range(at: 1)
            let codeRange = match.range(at: 2)
            
            let language = languageRange.location != NSNotFound
                ? (self as NSString).substring(with: languageRange)
                : nil
            
            let code = (self as NSString).substring(with: codeRange)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            return (language, code)
        }
    }
    
    /// Strips markdown formatting for plain text preview
    var strippingMarkdown: String {
        var result = self
        
        // Remove code blocks
        result = result.replacingOccurrences(of: #"```[\s\S]*?```"#, with: "[code]", options: .regularExpression)
        
        // Remove inline code
        result = result.replacingOccurrences(of: #"`([^`]+)`"#, with: "$1", options: .regularExpression)
        
        // Remove bold/italic
        result = result.replacingOccurrences(of: #"(\*\*\*|___)(.*?)\1"#, with: "$2", options: .regularExpression)
        result = result.replacingOccurrences(of: #"(\*\*|__)(.*?)\1"#, with: "$2", options: .regularExpression)
        result = result.replacingOccurrences(of: #"(\*|_)(.*?)\1"#, with: "$2", options: .regularExpression)
        
        // Remove headers
        result = result.replacingOccurrences(of: #"^#{1,6}\s*"#, with: "", options: .regularExpression)
        
        // Remove links but keep text
        result = result.replacingOccurrences(of: #"\[([^\]]+)\]\([^)]+\)"#, with: "$1", options: .regularExpression)
        
        return result.trimmed
    }
    
    /// Detects if string contains PII patterns (basic)
    var containsPotentialPII: Bool {
        // Email pattern
        let emailPattern = #"[\w\.-]+@[\w\.-]+\.\w+"#
        // Phone pattern (basic US)
        let phonePattern = #"\b\d{3}[-.]?\d{3}[-.]?\d{4}\b"#
        // SSN pattern
        let ssnPattern = #"\b\d{3}-\d{2}-\d{4}\b"#
        
        let patterns = [emailPattern, phonePattern, ssnPattern]
        
        for pattern in patterns {
            if let _ = self.range(of: pattern, options: .regularExpression) {
                return true
            }
        }
        
        return false
    }
}

// MARK: - Subscript Access

extension String {
    subscript(safe index: Int) -> Character? {
        guard index >= 0 && index < self.count else { return nil }
        return self[self.index(self.startIndex, offsetBy: index)]
    }
    
    subscript(range: Range<Int>) -> String {
        let start = self.index(self.startIndex, offsetBy: max(0, range.lowerBound))
        let end = self.index(self.startIndex, offsetBy: min(self.count, range.upperBound))
        return String(self[start..<end])
    }
}
