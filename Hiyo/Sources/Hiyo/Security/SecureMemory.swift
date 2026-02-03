//
//  SecureMemory.swift
//  Hiyo
//
//  Secure memory handling with explicit cleanup.
//

import Foundation
import CryptoKit

// MARK: - Errors

enum SecureMemoryError: Error {
    case destroyed
    case randomGenerationFailed(OSStatus)
}

// MARK: - SecureMemory (Data-only)

/// Manages sensitive Data with best-effort secure memory handling.
final class SecureMemory {
    private var value: Data?
    private let lock = NSLock()

    init(_ value: Data) {
        self.value = value
    }

    /// Access value with thread safety and mutation support.
    func withValue<R>(_ closure: (inout Data) throws -> R) throws -> R {
        lock.lock()
        defer { lock.unlock() }

        guard var data = value else {
            throw SecureMemoryError.destroyed
        }

        let result = try closure(&data)
        // Write back any mutations
        value = data
        return result
    }

    /// Reads value without modification.
    func read<R>(_ closure: (Data) throws -> R) throws -> R {
        lock.lock()
        defer { lock.unlock() }

        guard let data = value else {
            throw SecureMemoryError.destroyed
        }

        return try closure(data)
    }

    /// Best-effort secure clear of memory.
    func destroy() {
        lock.lock()
        defer { lock.unlock() }

        guard var data = value else {
            return
        }

        data.withUnsafeMutableBytes { ptr in
            if let baseAddress = ptr.baseAddress {
                memset(baseAddress, 0, ptr.count)
            }
        }

        value = nil
    }

    deinit {
        destroy()
    }
}

// MARK: - SecureKey

/// Secure key wrapper that clears from memory after use.
/// Intended for ephemeral keys; long-lived keys should use Keychain.
struct SecureKey {
    private let secureData: SecureMemory

    init(data: Data) {
        self.secureData = SecureMemory(data)
    }

    init(size: Int = 32) throws {
        var keyData = Data(count: size)

        let status = keyData.withUnsafeMutableBytes { buffer -> OSStatus in
            guard let baseAddress = buffer.baseAddress else {
                return errSecAllocate
            }
            return SecRandomCopyBytes(kSecRandomDefault, size, baseAddress)
        }

        guard status == errSecSuccess else {
            throw SecureMemoryError.randomGenerationFailed(status)
        }

        self.secureData = SecureMemory(keyData)
    }

    func withSymmetricKey<R>(_ operation: (SymmetricKey) throws -> R) throws -> R {
        try secureData.read { data in
            let key = SymmetricKey(data: data)
            return try operation(key)
        }
    }

    func withData<R>(_ operation: (Data) throws -> R) throws -> R {
        try secureData.read(operation)
    }

    func destroy() {
        secureData.destroy()
    }
}
