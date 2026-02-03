//
//  HiyoStore.swift
//  Hiyo
//
//  SwiftData persistence layer with encryption.
//

import SwiftData
import Foundation
import CryptoKit

@MainActor
final class HiyoStore: ObservableObject {
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    private let encryptionKey: SymmetricKey
    
    @Published var currentChat: Chat?
    @Published var chats: [Chat] = []
    @Published var error: Error?
    
    init() throws {
        // Generate or retrieve encryption key
        self.encryptionKey = try Self.retrieveOrCreateEncryptionKey()
        
        // Configure SwiftData with no cloud sync
        let schema = Schema([Chat.self, Message.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        
        self.modelContainer = try ModelContainer(for: schema, configurations: [config])
        self.modelContext = ModelContext(modelContainer)
        self.modelContext.autosaveEnabled = true
        
        fetchChats()
    }
    
    // MARK: - Chat Management
    
    func createChat(title: String, model: String) -> Chat {
        let sanitizedTitle = String(title.prefix(200))
        let chat = Chat(title: sanitizedTitle, modelIdentifier: model)
        
        modelContext.insert(chat)
        
        do {
            try modelContext.save()
            fetchChats()
            currentChat = chat
            SecurityLogger.log(.modelLoaded, details: "Created chat: \(chat.id)")
        } catch {
            self.error = error
        }
        
        return chat
    }
    
    func deleteChat(_ chat: Chat) {
        modelContext.delete(chat)
        
        if currentChat?.id == chat.id {
            currentChat = nil
        }
        
        do {
            try modelContext.save()
            fetchChats()
            SecurityLogger.log(.dataCleared, details: "Deleted chat: \(chat.id)")
        } catch {
            self.error = error
        }
    }
    
    func duplicateChat(_ chat: Chat) {
        let newChat = Chat(title: chat.title + " Copy", modelIdentifier: chat.modelIdentifier)
        
        for message in chat.messages {
            let newMessage = Message(content: message.content, role: message.role)
            newMessage.tokensUsed = message.tokensUsed
            newMessage.latencyMs = message.latencyMs
            newChat.messages.append(newMessage)
        }
        
        modelContext.insert(newChat)
        
        do {
            try modelContext.save()
            fetchChats()
            currentChat = newChat
        } catch {
            self.error = error
        }
    }
    
    // MARK: - Message Management
    
    func addMessage(_ content: String, role: MessageRole, to chat: Chat) -> Message {
        let sanitizedContent = String(content.prefix(SecurityLimits.maxInputLength))
        let message = Message(content: sanitizedContent, role: role)
        
        chat.messages.append(message)
        chat.modifiedAt = Date()
        
        do {
            try modelContext.save()
        } catch {
            self.error = error
        }
        
        return message
    }
    
    func clearMessages(in chat: Chat) {
        chat.messages.removeAll()
        chat.modifiedAt = Date()
        
        do {
            try modelContext.save()
        } catch {
            self.error = error
        }
    }
    
    // MARK: - Data Export/Import
    
    func exportChats(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        // Validate extension
        guard url.pathExtension == "hiyo" || url.pathExtension == "encrypted" else {
            throw FileError.invalidPath
        }
        
        let data = try encoder.encode(chats)
        
        // Encrypt
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey)
        
        guard let combined = sealedBox.combined else {
            throw SecurityError.encryptionFailed
        }
        
        try SecureFileManager.createSecureFile(at: url, contents: combined)
        SecurityLogger.log(.exportOperation, details: "Exported to \(url.lastPathComponent)")
    }
    
    func importChats(from url: URL) async throws {
        guard url.pathExtension == "hiyo" || url.pathExtension == "encrypted" else {
            throw FileError.invalidPath
        }
        
        // Capture key for background task
        let key = self.encryptionKey
        
        // Decode to DTOs in background to ensure Sendable safety
        let importedDTOs = try await Task.detached(priority: .userInitiated) {
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decrypted = try AES.GCM.open(sealedBox, using: key)

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([ChatDTO].self, from: decrypted)
        }.value
        
        // Validate and import
        for chatDTO in importedDTOs {
            guard chatDTO.messages.count < 10000 else {
                throw SecurityError.validationFailed("Chat too large")
            }
            
            // Create new IDs to avoid conflicts
            let newChat = Chat(title: chatDTO.title, modelIdentifier: chatDTO.modelIdentifier)
            newChat.createdAt = chatDTO.createdAt
            newChat.modifiedAt = Date()
            
            for msgDTO in chatDTO.messages {
                let newMsg = Message(content: msgDTO.content, role: msgDTO.role)
                newMsg.timestamp = msgDTO.timestamp
                newMsg.tokensUsed = msgDTO.tokensUsed
                newChat.messages.append(newMsg)
            }
            
            modelContext.insert(newChat)
        }
        
        try modelContext.save()
        fetchChats()
        SecurityLogger.log(.importOperation, details: "Imported \(importedDTOs.count) chats")
    }
    
    func clearAllData() {
        do {
            try modelContext.delete(model: Chat.self)
            try modelContext.save()
            chats = []
            currentChat = nil
            
            // Clear caches
            try? SecureMLX.clearAllCaches()
            SecurityLogger.log(.dataCleared, details: "All data cleared")
        } catch {
            self.error = error
        }
    }
    
    func fetchChats() {
        let descriptor = FetchDescriptor<Chat>(
            sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)]
        )
        
        do {
            chats = try modelContext.fetch(descriptor)
        } catch {
            chats = []
            self.error = error
        }
    }
    
    // MARK: - Private Methods
    
    private static func retrieveOrCreateEncryptionKey() throws -> SymmetricKey {
        let keyTag = "ai.hiyo.mac.encryptionkey"
        
        // Try to retrieve existing
        if let data = try? SecureKeychain.load(account: keyTag) {
            return SymmetricKey(data: data)
        }
        
        // Generate new key
        var keyData = Data(count: 32)
        _ = keyData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!)
        }
        
        let key = SymmetricKey(data: keyData)
        
        // Store in keychain
        try SecureKeychain.save(data: keyData, account: keyTag)
        
        // Clear temporary data
        keyData.withUnsafeMutableBytes { memset($0.baseAddress, 0, $0.count) }
        
        return key
    }
}

enum SecurityError: Error {
    case encryptionFailed
    case validationFailed(String)
}

// MARK: - Import DTOs

private struct ChatDTO: Codable, Sendable {
    let id: UUID
    let title: String
    let createdAt: Date
    let modifiedAt: Date
    let messages: [MessageDTO]
    let modelIdentifier: String
}

private struct MessageDTO: Codable, Sendable {
    let id: UUID
    let content: String
    let role: MessageRole
    let timestamp: Date
    let tokensUsed: Int?
    let latencyMs: Double?
}
