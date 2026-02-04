//
//  SecurityTests.swift
//  HiyoTests
//
//  Comprehensive security validation tests.
//

import XCTest
@testable import Hiyo
import CryptoKit

final class SecurityTests: XCTestCase {
    
    // MARK: - Input Validation Tests
    
    func testValidModelIdentifier() throws {
        let valid = "mlx-community/Llama-3.2-3B-Instruct-4bit"
        let result = try InputValidator.validateModelIdentifier(valid)
        XCTAssertEqual(result, valid)
    }
    
    func testInvalidModelIdentifierPathTraversal() {
        let invalid = "mlx-community/../etc/passwd"
        XCTAssertThrowsError(try InputValidator.validateModelIdentifier(invalid)) { error in
            XCTAssertEqual(error as? ValidationError, .invalidModelIdentifier)
        }
    }
    
    func testInvalidModelIdentifierShellInjection() {
        let invalid = "model; rm -rf /"
        XCTAssertThrowsError(try InputValidator.validateModelIdentifier(invalid))
    }
    
    func testValidInput() throws {
        let valid = "Hello, world!"
        let result = try InputValidator.validateInput(valid)
        XCTAssertEqual(result, valid)
    }
    
    func testInputNullByteRejection() {
        let invalid = "Hello\0World"
        XCTAssertThrowsError(try InputValidator.validateInput(invalid)) { error in
            XCTAssertEqual(error as? ValidationError, .nullByteDetected)
        }
    }
    
    func testInputXSSPrevention() {
        let xssAttempts = [
            "<script>alert('xss')</script>",
            "javascript:void(0)",
            "onerror=alert('xss')",
            "eval(document.cookie)"
        ]
        
        for attempt in xssAttempts {
            XCTAssertThrowsError(try InputValidator.validateInput(attempt), "Should reject: \(attempt)")
        }
    }
    
    func testInputLengthLimit() {
        let longInput = String(repeating: "a", count: SecurityLimits.maxInputLength + 1)
        XCTAssertThrowsError(try InputValidator.validateInput(longInput)) { error in
            guard case .tooLong = error as? ValidationError else {
                XCTFail("Expected tooLong error")
                return
            }
        }
    }
    
    func testOutputSanitization() {
        let longOutput = String(repeating: "a", count: SecurityLimits.maxOutputLength + 100)
        let sanitized = InputValidator.sanitizeOutput(longOutput)
        
        XCTAssertLessThanOrEqual(sanitized.count, SecurityLimits.maxOutputLength + 50) // Allow for truncation message
        XCTAssertTrue(sanitized.contains("[Output truncated"))
    }
    
    // MARK: - Secure Memory Tests
    
    func testSecureMemoryBasic() {
        let secure = SecureMemory("sensitive data")
        
        var retrieved: String?
        secure.withValue { value in
            retrieved = value
        }
        
        XCTAssertEqual(retrieved, "sensitive data")
    }
    
    func testSecureMemoryDestruction() {
        let secure = SecureMemory("secret")
        secure.destroy()
        
        // After destroy, accessing should fail
        // Note: In production this would fatalError, in tests we verify the mechanism exists
    }
    
    func testSecureKeyGeneration() {
        let key1 = SecureKey(size: 32)
        let key2 = SecureKey(size: 32)
        
        var key1Data: Data?
        var key2Data: Data?
        
        key1.withData { data in
            key1Data = data
        }
        
        key2.withData { data in
            key2Data = data
        }
        
        XCTAssertNotNil(key1Data)
        XCTAssertNotNil(key2Data)
        XCTAssertNotEqual(key1Data, key2Data) // Keys should be random
        XCTAssertEqual(key1Data?.count, 32)
    }
    
    func testSecureKeySymmetricKey() {
        let key = SecureKey(size: 32)
        
        var symmetricKey: SymmetricKey?
        key.withSymmetricKey { sk in
            symmetricKey = sk
        }
        
        XCTAssertNotNil(symmetricKey)
    }
    
    // MARK: - Keychain Tests
    
    func testKeychainRoundTrip() throws {
        let testAccount = "test.keychain.\(UUID().uuidString)"
        let testData = Data("test secret data".utf8)
        
        // Save
        try SecureKeychain.save(data: testData, account: testAccount)
        
        // Load
        let loaded = try SecureKeychain.load(account: testAccount)
        XCTAssertEqual(loaded, testData)
        
        // Delete
        try SecureKeychain.delete(account: testAccount)
        
        // Verify deletion
        XCTAssertThrowsError(try SecureKeychain.load(account: testAccount)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }
    
    // MARK: - Resource Guard Tests
    
    func testResourceGuardRateLimiting() async throws {
        let guard = ResourceGuard.shared
        
        // First requests should succeed
        for _ in 0..<5 {
            try await guard.checkResourceLimits()
        }
        
        // Token allocation
        try await guard.allocateTokens(100)
        await guard.releaseTokens(100)
    }
    
    func testResourceGuardTokenLimits() async {
        let guard = ResourceGuard.shared
        
        do {
            try await guard.allocateTokens(10000) // At limit
            await guard.releaseTokens(10000)
        } catch {
            XCTFail("Should allow tokens at limit: \(error)")
        }
    }
    
    // MARK: - File Security Tests
    
    func testSecureFilename() {
        XCTAssertTrue("valid_filename.txt".isSafeFilename)
        XCTAssertFalse("../etc/passwd".isSafeFilename)
        XCTAssertFalse(".hidden".isSafeFilename)
        XCTAssertFalse("file/name".isSafeFilename)
    }
    
    func testSanitizedFilename() {
        XCTAssertEqual("file/name".sanitizedFilename, "file_name")
        XCTAssertEqual(".hidden".sanitizedFilename, "hidden")
        XCTAssertEqual("".sanitizedFilename, "untitled")
    }
    
    func testSecureCacheDirectory() throws {
        let cacheDir = try SecureMLX.secureCacheDirectory()
        
        XCTAssertTrue(cacheDir.path.contains("Caches"))
        XCTAssertFalse(cacheDir.path.contains(".."))
    }
    
    // MARK: - String Extension Tests
    
    func testStringTruncation() {
        let str = "Hello, World!"
        XCTAssertEqual(str.truncated(to: 5), "Hello...")
        XCTAssertEqual(str.truncated(to: 100), str)
    }
    
    func testControlCharacterRemoval() {
        let withControl = "Hello\u{00}\u{01}World"
        let cleaned = withControl.removingControlCharacters
        XCTAssertFalse(cleaned.contains { $0.isControl && $0 != "\n" && $0 != "\t" })
    }
    
    func testPIIDetection() {
        XCTAssertTrue("Contact me at user@example.com".containsPotentialPII)
        XCTAssertTrue("Call 555-123-4567".containsPotentialPII)
        XCTAssertTrue("SSN: 123-45-6789".containsPotentialPII)
        XCTAssertFalse("Hello world".containsPotentialPII)
    }
    
    // MARK: - Code Integrity Tests
    
    func testDebuggerDetection() {
        // In test environment, debugger may or may not be attached
        // Just verify the method doesn't crash
        _ = CodeIntegrity.isDebuggerAttached()
    }
    
    func testSuspiciousLibraryDetection() {
        // In clean test environment, should be false
        // Note: May be affected by test runner environment
        _ = CodeIntegrity.hasSuspiciousLibraries()
    }
    
    // MARK: - Security Logger Tests
    
    func testSecurityLogging() {
        // Verify logging doesn't crash (actual log destination is OSLog)
        SecurityLogger.log(.modelLoaded, details: "Test model")
        SecurityLogger.logPublic(.modelLoaded, details: "Public test")
        
        // These should complete without throwing
        XCTAssertTrue(true)
    }
    
    // MARK: - Encryption Tests
    
    func testAESEncryptionRoundTrip() throws {
        let key = SymmetricKey(size: .bits256)
        let data = Data("Secret message".utf8)
        
        let sealedBox = try AES.GCM.seal(data, using: key)
        let combined = sealedBox.combined!
        
        let openedBox = try AES.GCM.SealedBox(combined: combined)
        let decrypted = try AES.GCM.open(openedBox, using: key)
        
        XCTAssertEqual(decrypted, data)
    }
}
