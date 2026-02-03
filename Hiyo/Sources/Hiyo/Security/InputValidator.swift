//
//  InputValidator.swift
//  Hiyo
//
//  Input sanitization and validation for all user inputs.
//

import Foundation

enum InputValidator {
    static let maxInputLength = 10000
    static let maxOutputLength = 50000
    
    /// Validates model identifiers (Hugging Face format)
    static func validateModelIdentifier(_ model: String) throws -> String {
        // Hugging Face format: username/model-name
        let pattern = #"^[a-zA-Z0-9_-]+/[a-zA-Z0-9._-]+$"#
        
        guard model.range(of: pattern, options: .regularExpression) != nil else {
            throw ValidationError.invalidModelIdentifier
        }
        
        // Block dangerous characters
        let blockedChars = ["..", "../", "./", ":", ";", "|", "&", "$", "`", "\\0"]
        for char in blockedChars {
            guard !model.contains(char) else {
                throw ValidationError.suspiciousCharacters
            }
        }
        
        // Length check
        guard model.count <= 100 else {
            throw ValidationError.tooLong(model.count, 100)
        }
        
        return model
    }
    
    /// Validates user chat input
    static func validateInput(_ input: String) throws -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            throw ValidationError.emptyInput
        }
        
        guard trimmed.count <= maxInputLength else {
            throw ValidationError.tooLong(trimmed.count, maxInputLength)
        }
        
        // Null byte check
        guard !trimmed.contains("\0") else {
            throw ValidationError.nullByteDetected
        }
        
        // Control character check
        let controlChars = trimmed.unicodeScalars.filter { 
            $0.properties.isControl && 
            $0 != " " && 
            $0 != "\n" && 
            $0 != "\t" && 
            $0 != "\r"
        }
        guard controlChars.isEmpty else {
            throw ValidationError.controlCharacters
        }
        
        // XSS/script injection prevention
        let dangerousPatterns = [
            "<script", "javascript:", "onerror=", "onload=", "onfocus=",
            "eval(", "document.", "window.", "alert(", "prompt(",
            "confirm(", "fetch(", "XMLHttpRequest"
        ]
        
        let lowercased = trimmed.lowercased()
        for pattern in dangerousPatterns {
            guard !lowercased.contains(pattern) else {
                throw ValidationError.potentiallyMalicious
            }
        }
        
        return trimmed
    }
    
    /// Sanitizes model output for display
    static func sanitizeOutput(_ output: String) -> String {
        var sanitized = output
        
        // Truncate excessive length
        if sanitized.count > maxOutputLength {
            sanitized = String(sanitized.prefix(maxOutputLength))
            sanitized += "\n\n[Output truncated for security]"
        }
        
        // Remove null bytes
        sanitized = sanitized.replacingOccurrences(of: "\0", with: "")
        
        // Normalize line endings
        sanitized = sanitized.replacingOccurrences(of: "\r\n", with: "\n")
        sanitized = sanitized.replacingOccurrences(of: "\r", with: "\n")
        
        return sanitized
    }
    
    /// Validates file paths
    static func validateFilePath(_ path: String, allowDirectory: Bool = false) throws -> URL {
        // Normalize path
        let url = URL(fileURLWithPath: path).standardizedFileURL
        
        // Check for traversal
        let pathString = url.path
        guard !pathString.contains("..") else {
            throw ValidationError.directoryTraversal
        }
        
        // Must be within allowed directories
        let allowedPrefixes = [
            SecureFileManager.appSupportDirectory.path,
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path,
            FileManager.default.temporaryDirectory.path
        ].compactMap { $0 }
        
        guard allowedPrefixes.contains(where: pathString.hasPrefix) else {
            throw ValidationError.invalidPath
        }
        
        // Check if directory (when not allowed)
        if !allowDirectory {
            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: pathString, isDirectory: &isDir)
            guard !isDir.boolValue else {
                throw ValidationError.isDirectory
            }
        }
        
        return url
    }
}

enum ValidationError: Error {
    case invalidModelIdentifier
    case suspiciousCharacters
    case emptyInput
    case tooLong(Int, Int)
    case nullByteDetected
    case controlCharacters
    case potentiallyMalicious
    case directoryTraversal
    case invalidPath
    case isDirectory
    
    var localizedDescription: String {
        switch self {
        case .invalidModelIdentifier: 
            return "Invalid model identifier. Use format: username/model-name"
        case .suspiciousCharacters: 
            return "Input contains suspicious characters"
        case .emptyInput: 
            return "Input cannot be empty"
        case .tooLong(let got, let max): 
            return "Input too long (\(got) > \(max) characters)"
        case .nullByteDetected: 
            return "Null bytes not allowed"
        case .controlCharacters: 
            return "Control characters not allowed"
        case .potentiallyMalicious: 
            return "Potentially malicious content detected"
        case .directoryTraversal: 
            return "Directory traversal not allowed"
        case .invalidPath: 
            return "Invalid file path"
        case .isDirectory: 
            return "Expected file, got directory"
        }
    }
}
