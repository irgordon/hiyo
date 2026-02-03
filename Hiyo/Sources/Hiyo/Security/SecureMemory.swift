//
//  SecureMemory.swift
//  Hiyo
//
//  Secure memory handling with explicit cleanup.
//

import Foundation
import CryptoKit

/// Manages sensitive data with secure memory handling
final class SecureMemory<T> {
    private var _value: T?
    private let lock = NSLock()
    
    init(_ value: T) {
        self._value = value
    }
    
    /// Access value with thread safety
    func withValue<R>(_ closure: (inout T) throws -> R) rethrows -> R {
        lock.lock()
        defer { lock.unlock() }
        
        guard var value = _value else {
            fatalError("Accessing destroyed secure memory")
        }
        
        return try closure(&value)
    }
    
    /// Reads value without modification
    func read<R>(_ closure: (T) throws -> R) rethrows -> R {
        lock.lock()
        defer { lock.unlock() }
        
        guard let value = _value else {
            fatalError("Accessing destroyed secure memory")
        }
        
        return try closure(value)
    }
    
    /// Securely clears memory
    func destroy() {
        lock.lock()
        defer { lock.unlock() }
        
        // For Data types, overwrite with zeros before deallocation
        if var data = _value as? Data {
            data.withUnsafeMutableBytes { ptr in
                if let baseAddress = ptr.baseAddress {
                    memset(baseAddress, 0, ptr.count)
                }
            }
        }
        
        _value = nil
    }
    
    deinit {
        destroy()
    }
}

/// Secure key wrapper that clears from memory after use
struct SecureKey {
    private let secureData: SecureMemory<Data>
    
    init(data: Data) {
        self.secureData = SecureMemory(data)
    }
    
    init(size: Int = 32) {
        var keyData = Data(count: size)
        _ = keyData.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, size, $0.baseAddress!) }
        self.secureData = SecureMemory(keyData)
    }
    
    func withSymmetricKey<R>(_ operation: (SymmetricKey) throws -> R) rethrows -> R {
        try secureData.read { data in
            let key = SymmetricKey(data: data)
            return try operation(key)
        }
    }
    
    func withData<R>(_ operation: (Data) throws -> R) rethrows -> R {
        try secureData.read(operation)
    }
    
    func destroy() {
        secureData.destroy()
    }
}
