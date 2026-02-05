//
//  HiyoStore.swift
//  Hiyo
//
//  SwiftData persistence layer with encryption.
//

import SwiftData
import Foundation
import CryptoKit
import Observation

@MainActor
@Observable
final class HiyoStore {
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    private let encryptionKey: SymmetricKey
    
    var currentChat: Chat?
    var chats: [Chat] = []
    var error: Error?
    
    init() throws {
        // Generate or retrieve encryption key
        self.encryptionKey = try Self.retrieveOrCreateEncryptionKey()
        
        // Secure the storage directory
        try Self.secureStorageDirectory()

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

        // Perform migration for denormalized fields
        let container = modelContainer
        Task.detached {
            try? await Self.performMigration(container: container)
        }
    }
    
    // MARK: - Chat Management
    
    func createChat(title: String, model: String) -> Chat {
        let sanitizedTitle = String(title.prefix(200))
        let chat = Chat(title: sanitizedTitle, modelIdentifier: model)
        
        modelContext.insert(chat)
        
        do {
            try modelContext.save()
            chats.insert(chat, at: 0)
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
            chats.removeAll { $0.id == chat.id }
            SecurityLogger.log(.dataCleared, details: "Deleted chat: \(chat.id)")
        } catch {
            self.error = error
        }
    }
    
    func duplicateChat(_ chat: Chat) {
        let chatID = chat.persistentModelID
        let container = modelContainer
        
        Task.detached {
            let context = ModelContext(container)

            // Fetch original chat in background context
            guard let originalChat = context.model(for: chatID) as? Chat else { return }

            let newChat = Chat(title: originalChat.title + " Copy", modelIdentifier: originalChat.modelIdentifier)

            // Sort messages to guarantee order
            let sortedMessages = originalChat.messages.sorted { $0.timestamp < $1.timestamp }

            var totalTokens = 0
            for message in sortedMessages {
                let newMessage = Message(content: message.content, role: message.role)
                newMessage.tokensUsed = message.tokensUsed
                newMessage.latencyMs = message.latencyMs
                newChat.messages.append(newMessage)
                if let t = message.tokensUsed { totalTokens += t }
            }

            // Update denormalized fields
            newChat.messageCountCache = sortedMessages.count
            newChat.lastMessagePreview = sortedMessages.last?.preview
            newChat.totalTokensCache = totalTokens

            context.insert(newChat)

            do {
                try context.save()
                let newChatID = newChat.persistentModelID

                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    // Fetch the new chat on the main context
                    if let mainThreadNewChat = self.modelContext.model(for: newChatID) as? Chat {
                        self.chats.insert(mainThreadNewChat, at: 0)
                        self.currentChat = mainThreadNewChat
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.error = error
                }
            }
        }
    }
    
    func searchChats(query: String) -> [Chat] {
        if query.isEmpty {
            return chats
        }

        let predicate = #Predicate<Chat> { chat in
            chat.title.localizedStandardContains(query) ||
            chat.messages.contains { message in
                message.content.localizedStandardContains(query)
            }
        }

        let descriptor = FetchDescriptor<Chat>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            self.error = error
            return []
        }
    }

    // MARK: - Message Management
    
    func addMessage(_ content: String, role: MessageRole, to chat: Chat) -> Message {
        let sanitizedContent = String(content.prefix(SecurityLimits.maxInputLength))
        let message = Message(content: sanitizedContent, role: role)
        
        chat.messages.append(message)
        chat.modifiedAt = Date()
        
        // Update denormalized fields
        chat.applyMessageAdded(message)

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
        
        // Update denormalized fields
        chat.updateDerivedFields()

        do {
            try modelContext.save()
        } catch {
            self.error = error
        }
    }
    
    // MARK: - Data Export/Import
    
    func exportChats(to url: URL) async throws {
        // Validate extension
        guard url.pathExtension == "hiyo" || url.pathExtension == "encrypted" else {
            throw FileError.invalidPath
        }

        // Map to DTOs on Main Actor (safe SwiftData access)
        let chatDTOs = self.chats.map { chat in
            ChatDTO(
                id: chat.id,
                title: chat.title,
                createdAt: chat.createdAt,
                modifiedAt: chat.modifiedAt,
                messages: chat.messages.map { msg in
                    MessageDTO(
                        id: msg.id,
                        content: msg.content,
                        role: msg.role,
                        timestamp: msg.timestamp,
                        tokensUsed: msg.tokensUsed,
                        latencyMs: msg.latencyMs
                    )
                },
                modelIdentifier: chat.modelIdentifier
            )
        }
        
        // Capture key for background task
        let key = self.encryptionKey

        // Offload encoding, encryption, and writing to detached task
        try await Task.detached(priority: .userInitiated) {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601

            // Encode
            let data = try encoder.encode(chatDTOs)

            // Encrypt
            let sealedBox = try AES.GCM.seal(data, using: key)

            guard let combined = sealedBox.combined else {
                throw SecurityError.encryptionFailed
            }

            try SecureFileManager.createSecureFile(at: url, contents: combined)
            SecurityLogger.log(.exportOperation, details: "Exported to \(url.lastPathComponent)")
        }.value
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
        var newChats: [Chat] = []
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
            
            // Update denormalized fields
            newChat.updateDerivedFields()

            modelContext.insert(newChat)
            newChats.append(newChat)
        }
        
        try modelContext.save()
        chats.insert(contentsOf: newChats, at: 0)
        SecurityLogger.log(.importOperation, details: "Imported \(importedDTOs.count) chats")
    }
    
    func clearAllData() {
        do {
            try modelContext.delete(model: Chat.self)
            try modelContext.save()
            chats = []
            currentChat = nil
            
            // Clear caches
            Task.detached {
                try? await SecureMLX.clearAllCaches()
                SecurityLogger.log(.dataCleared, details: "All data cleared")
            }
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
    
    private static func secureStorageDirectory() throws {
        let fileManager = FileManager.default
        let appSupport = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

        // Enable encryption at rest for the entire storage directory
        let attributes: [FileAttributeKey: Any] = [
            .protectionKey: FileProtectionType.complete
        ]

        try fileManager.setAttributes(attributes, ofItemAtPath: appSupport.path)
    }

    private static func performMigration(container: ModelContainer) async throws {
        let context = ModelContext(container)
        // Optimization: Fetch chats that need migration (missing cache or tokens)
        // Since totalTokensCache is new, we check if it is 0.
        let predicate = #Predicate<Chat> { $0.totalTokensCache == 0 }
        let descriptor = FetchDescriptor<Chat>(predicate: predicate)
        let chats = try context.fetch(descriptor)

        var modified = false
        for chat in chats {
            // Check if truly unmigrated (has messages)
            if !chat.messages.isEmpty {
                chat.updateDerivedFields()
                modified = true
            }
        }

        if modified {
            try context.save()
        }
    }

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
