//
//  SecurityLogger.swift
//  Hiyo
//
//  Centralized security event logging.
//

import Foundation
import OSLog

enum SecurityLogger {
    private static let logger = Logger(subsystem: "ai.hiyo.mac", category: "security")
    private static let queue = DispatchQueue(label: "ai.hiyo.securitylog", qos: .utility)
    
    /// Logs security event without sensitive data
    static func log(_ event: SecurityEvent, details: String = "") {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let sanitizedDetails = sanitize(details)
        
        queue.async {
            logger.error("[\(timestamp)] \(event.rawValue): \(sanitizedDetails, privacy: .private)")
            
            // In production: write to encrypted log file or secure backend
            // Do NOT print to console in release builds
            #if DEBUG
            print("[SECURITY] \(event.rawValue): \(sanitizedDetails)")
            #endif
        }
    }
    
    /// Logs with public visibility (non-sensitive)
    static func logPublic(_ event: SecurityEvent, details: String) {
        logger.info("[SECURITY] \(event.rawValue): \(details)")
    }
    
    /// Sanitizes potentially sensitive strings
    private static func sanitize(_ input: String) -> String {
        // Remove potential PII patterns
        var sanitized = input
        
        // Truncate long strings
        if sanitized.count > 200 {
            sanitized = String(sanitized.prefix(200)) + "..."
        }
        
        // Remove control characters
        sanitized = sanitized.components(separatedBy: .controlCharacters).joined()
        
        return sanitized
    }
    
    enum SecurityEvent: String {
        // Integrity
        case integrityCheckFailed = "INTEGRITY_CHECK_FAILED"
        case integrityViolation = "INTEGRITY_VIOLATION"
        case suspiciousEnvironment = "SUSPICIOUS_ENVIRONMENT"
        
        // Sandbox
        case sandboxEscapeAttempt = "SANDBOX_ESCAPE_ATTEMPT"
        case invalidFileAccess = "INVALID_FILE_ACCESS"
        
        // Input
        case invalidInput = "INVALID_INPUT"
        case injectionAttempt = "INJECTION_ATTEMPT"
        
        // Network (defense)
        case networkBlocked = "NETWORK_BLOCKED"
        
        // Model
        case modelLoaded = "MODEL_LOADED"
        case modelUnloaded = "MODEL_UNLOADED"
        case modelLoadFailed = "MODEL_LOAD_FAILED"
        case generationCompleted = "GENERATION_COMPLETED"
        
        // Data
        case exportOperation = "EXPORT_OPERATION"
        case importOperation = "IMPORT_OPERATION"
        case dataCleared = "DATA_CLEARED"
    }
}
