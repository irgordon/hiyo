//
//  ResourceGuard.swift
//  Hiyo
//
//  Actor-based resource limiting and DoS prevention.
//

import Foundation

actor ResourceGuard {
    static let shared = ResourceGuard()
    
    private var activeTokens: Int = 0
    private let maxConcurrentTokens = 10000
    
    private var requestTimestamps: [Date] = []
    private let maxRequestsPerMinute = 60
    private let maxRequestsPerSecond = 10
    
    private var lastCleanup = Date()
    private let cleanupInterval: TimeInterval = 60
    
    /// Checks all resource limits
    func checkResourceLimits() throws {
        let now = Date()
        
        // Periodic cleanup
        if now.timeIntervalSince(lastCleanup) > cleanupInterval {
            requestTimestamps.removeAll { now.timeIntervalSince($0) > cleanupInterval }
            lastCleanup = now
        }
        
        // Per-second rate limit
        let recentSecond = requestTimestamps.filter { now.timeIntervalSince($0) < 1.0 }
        guard recentSecond.count < maxRequestsPerSecond else {
            throw ResourceError.rateLimitExceeded("Too many requests per second")
        }
        
        // Per-minute rate limit
        guard requestTimestamps.count < maxRequestsPerMinute else {
            throw ResourceError.rateLimitExceeded("Too many requests per minute")
        }
        
        // Memory pressure check
        try enforceMemoryLimit()
        
        requestTimestamps.append(now)
    }
    
    /// Allocates token budget for generation
    func allocateTokens(_ count: Int) throws {
        guard count > 0 && count <= 8192 else {
            throw ResourceError.invalidTokenCount
        }
        
        guard activeTokens + count <= maxConcurrentTokens else {
            throw ResourceError.contextWindowExceeded
        }
        
        activeTokens += count
    }
    
    /// Releases token budget
    func releaseTokens(_ count: Int) {
        activeTokens = max(0, activeTokens - count)
    }
    
    /// Checks available system memory
    func enforceMemoryLimit() throws {
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        let usedMemory = reportMemoryUsage()
        
        // Fail if using more than 80% of physical memory
        if Double(usedMemory) > Double(physicalMemory) * 0.8 {
            throw ResourceError.memoryLimitExceeded
        }
    }
    
    /// Reports current memory usage in bytes
    private func reportMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        guard kerr == KERN_SUCCESS else {
            return 0
        }
        
        return info.resident_size
    }
}

enum ResourceError: Error {
    case rateLimitExceeded(String)
    case contextWindowExceeded
    case invalidTokenCount
    case memoryLimitExceeded
    
    var localizedDescription: String {
        switch self {
        case .rateLimitExceeded(let msg): return msg
        case .contextWindowExceeded: return "Context window exceeded. Start a new conversation."
        case .invalidTokenCount: return "Invalid token count"
        case .memoryLimitExceeded: return "System memory limit exceeded. Close other apps and try again."
        }
    }
}

import Darwin.mach.mach_init
import Darwin.mach.task_info
