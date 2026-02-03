//
//  CodeIntegrity.swift
//  Hiyo
//
//  Runtime code signing verification and anti-tampering.
//

import Foundation
import Security

enum CodeIntegrity {
    /// Validates app signature at runtime
    static func verifyIntegrity() -> Bool {
        var code: SecCode?
        let status = SecCodeCopySelf(
            SecCSFlags(rawValue: kSecCSDefaultFlags),
            &code
        )
        
        guard status == errSecSuccess, let code = code else {
            SecurityLogger.log(.integrityCheckFailed, details: "Failed to copy self code")
            return false
        }
        
        // Check for dynamic validity
        let dynamicStatus = SecCodeCheckValidity(
            code,
            SecCSFlags(rawValue: kSecCSCheckAllArchitectures),
            nil
        )
        
        if dynamicStatus != errSecSuccess {
            SecurityLogger.log(.integrityCheckFailed, details: "Code signature invalid")
            return false
        }
        
        return true
    }
    
    /// Detects debugger attachment
    static func isDebuggerAttached() -> Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                sysctl(&mib, u_int(mib.count), $0, &size, nil, 0)
            }
        }
        
        guard kerr == KERN_SUCCESS else { return false }
        
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }
    
    /// Detects code injection via DYLD
    static func hasSuspiciousLibraries() -> Bool {
        let suspiciousEnvVars = [
            "DYLD_INSERT_LIBRARIES",
            "DYLD_LIBRARY_PATH",
            "DYLD_FRAMEWORK_PATH"
        ]
        
        for varName in suspiciousEnvVars {
            if getenv(varName) != nil {
                SecurityLogger.log(.suspiciousEnvironment, details: varName)
                return true
            }
        }
        
        return false
    }
    
    /// Enforces integrity at launch
    static func enforceIntegrity() {
        #if !DEBUG
        if !verifyIntegrity() || isDebuggerAttached() || hasSuspiciousLibraries() {
            SecurityLogger.log(.integrityViolation, details: "App integrity compromised")
            
            // Delayed termination to allow log to sync
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSApp.terminate(nil)
            }
        }
        #endif
    }
}

// MARK: - Security Logger

enum SecurityLogger {
    private static let logger = Logger(subsystem: "ai.hiyo.mac", category: "security")
    
    static func log(_ event: SecurityEvent, details: String) {
        logger.error("[SECURITY] \(event.rawValue): \(details)")
        
        // In production, you might want to send to a secure logging service
        // or write to an encrypted local log file
    }
    
    enum SecurityEvent: String {
        case integrityCheckFailed = "INTEGRITY_CHECK_FAILED"
        case integrityViolation = "INTEGRITY_VIOLATION"
        case sandboxEscapeAttempt = "SANDBOX_ESCAPE_ATTEMPT"
        case injectionDetected = "CODE_INJECTION_DETECTED"
        case suspiciousEnvironment = "SUSPICIOUS_ENVIRONMENT"
        case modelLoaded = "MODEL_LOADED"
        case modelUnloaded = "MODEL_UNLOADED"
        case networkError = "NETWORK_ERROR"
    }
}

import OSLog
import Darwin.sys.sysctl
