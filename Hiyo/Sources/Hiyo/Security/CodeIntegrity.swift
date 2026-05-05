//
//  CodeIntegrity.swift
//  Hiyo
//
//  Runtime code signing verification and anti-tampering.
//

import Foundation
import Security

#if os(macOS)
import AppKit
#endif

enum CodeIntegrity {
    /// Validates app signature at runtime
    static func verifyIntegrity() -> Bool {
        #if os(macOS)
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
        #else
        return true
        #endif
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
            #if os(macOS)
                NSApp.terminate(nil)
            #else
            exit(1)
            #endif
            }
        }
        #endif
    }
}

import Darwin.sys.sysctl
