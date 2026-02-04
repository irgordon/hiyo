//
//  HiyoTests.swift
//  HiyoTests
//
//  Unit tests for core Hiyo functionality.
//

import XCTest
@testable import Hiyo
import SwiftData

@MainActor
final class HiyoTests: XCTestCase {
    
    var store: HiyoStore!
    
    override func setUp() async throws {
        try await super.setUp()
        store = try HiyoStore()
    }
    
    override func tearDown() async throws {
        store = nil
        try await super.tearDown()
    }
    
    // MARK: - HiyoStore Tests
    
    func testCreateChat() throws {
        let chat = store.createChat(title: "Test Chat", model: "test-model")
        
        XCTAssertEqual(chat.title, "Test Chat")
        XCTAssertEqual(chat.modelIdentifier, "test-model")
        XCTAssertTrue(chat.messages.isEmpty)
        XCTAssertNotNil(store.currentChat)
    }
    
    func testDeleteChat() throws {
        let chat = store.createChat(title: "To Delete", model: "test")
        let chatId = chat.id
        
        store.deleteChat(chat)
        
        XCTAssertNil(store.chats.first { $0.id == chatId })
        XCTAssertNil(store.currentChat)
    }
    
    func testDuplicateChat() throws {
        let original = store.createChat(title: "Original", model: "test")
        _ = store.addMessage("Hello", role: .user, to: original)
        
        store.duplicateChat(original)
        
        XCTAssertEqual(store.chats.count, 2)
        XCTAssertTrue(store.chats.contains { $0.title == "Original Copy" })
    }
    
    func testAddMessage() throws {
        let chat = store.createChat(title: "Test", model: "test")
        
        let message = store.addMessage("Test message", role: .user, to: chat)
        
        XCTAssertEqual(message.content, "Test message")
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(chat.messages.count, 1)
    }
    
    func testClearMessages() throws {
        let chat = store.createChat(title: "Test", model: "test")
        _ = store.addMessage("Message 1", role: .user, to: chat)
        _ = store.addMessage("Message 2", role: .assistant, to: chat)
        
        store.clearMessages(in: chat)
        
        XCTAssertTrue(chat.messages.isEmpty)
    }
    
    func testMessageTruncation() throws {
        let chat = store.createChat(title: "Test", model: "test")
        let longContent = String(repeating: "a", count: SecurityLimits.maxInputLength + 100)
        
        let message = store.addMessage(longContent, role: .user, to: chat)
        
        XCTAssertEqual(message.content.count, SecurityLimits.maxInputLength)
    }
    
    // MARK: - Chat Model Tests
    
    func testChatComputedProperties() throws {
        let chat = store.createChat(title: "Test", model: "test")
        
        XCTAssertEqual(chat.messageCount, 0)
        XCTAssertNil(chat.lastMessage)
        
        _ = store.addMessage("First", role: .user, to: chat)
        _ = store.addMessage("Second", role: .assistant, to: chat)
        
        XCTAssertEqual(chat.messageCount, 2)
        XCTAssertNotNil(chat.lastMessage)
        XCTAssertEqual(chat.lastMessage?.content, "Second")
    }
    
    // MARK: - Message Model Tests
    
    func testMessageRoles() throws {
        let userMsg = Message(content: "Hello", role: .user)
        let assistantMsg = Message(content: "Hi", role: .assistant)
        let systemMsg = Message(content: "System", role: .system)
        
        XCTAssertTrue(userMsg.isFromUser)
        XCTAssertFalse(userMsg.isFromAssistant)
        
        XCTAssertTrue(assistantMsg.isFromAssistant)
        XCTAssertFalse(assistantMsg.isFromUser)
        
        XCTAssertTrue(systemMsg.isSystem)
    }
    
    func testMessageDisplayContent() {
        let msg = Message(content: "Hello\0World", role: .user)
        XCTAssertFalse(msg.displayContent.contains("\0"))
    }
    
    // MARK: - Notification Tests
    
    func testSecureNotification() {
        let expectation = self.expectation(description: "Notification received")
        var receivedNotification = false
        
        let observer = SecureNotification.observe(name: .hiyoNewConversation) { _ in
            receivedNotification = true
            expectation.fulfill()
        }
        
        SecureNotification.post(name: .hiyoNewConversation)
        
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(receivedNotification)
        
        SecureNotification.remove(observer: observer)
    }
}
