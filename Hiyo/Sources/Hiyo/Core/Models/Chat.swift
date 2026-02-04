//
//  Chat.swift
//  Hiyo
//
//  Conversation container model for SwiftData.
//

import Foundation
import SwiftData

@Model
final class Chat {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var modifiedAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \Message.chat)
    var messages: [Message] = []
    
    var modelIdentifier: String
    
    // Denormalized fields for performance (N+1 avoidance)
    var lastMessagePreview: String?
    var messageCountCache: Int = 0

    init(title: String, modelIdentifier: String) {
        self.id = UUID()
        self.title = title
        self.modelIdentifier = modelIdentifier
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
    
    // MARK: - Computed Properties
    
    var messageCount: Int {
        // Fallback to relationship if cache is 0 but messages exist (e.g. migration pending)
        if messageCountCache == 0 && !messages.isEmpty {
            return messages.count
        }
        return messageCountCache
    }
    
    var lastMessage: Message? {
        messages.sorted { $0.timestamp < $1.timestamp }.last
    }
    
    var totalTokens: Int {
        messages.compactMap { $0.tokensUsed }.reduce(0, +)
    }
    
    var durationDescription: String {
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: createdAt, to: Date())
        
        if let days = components.day, days > 0 {
            return days == 1 ? "1 day" : "\(days) days"
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour" : "\(hours) hours"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 minute" : "\(minutes) minutes"
        } else {
            return "Just now"
        }
    }
    
    // MARK: - Methods
    
    func updateModifiedDate() {
        modifiedAt = Date()
    }
}

// MARK: - Codable Support

extension Chat: Codable {
    enum CodingKeys: String, CodingKey {
        case id, title, createdAt, modifiedAt, messages, modelIdentifier
        case lastMessagePreview, messageCountCache
    }
    
    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let title = try container.decode(String.self, forKey: .title)
        let modelIdentifier = try container.decode(String.self, forKey: .modelIdentifier)
        
        self.init(title: title, modelIdentifier: modelIdentifier)
        
        self.id = try container.decode(UUID.self, forKey: .id)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.modifiedAt = try container.decode(Date.self, forKey: .modifiedAt)
        self.messages = try container.decode([Message].self, forKey: .messages)

        self.lastMessagePreview = try container.decodeIfPresent(String.self, forKey: .lastMessagePreview)
        self.messageCountCache = try container.decodeIfPresent(Int.self, forKey: .messageCountCache) ?? 0
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(modifiedAt, forKey: .modifiedAt)
        try container.encode(messages, forKey: .messages)
        try container.encode(modelIdentifier, forKey: .modelIdentifier)
        try container.encode(lastMessagePreview, forKey: .lastMessagePreview)
        try container.encode(messageCountCache, forKey: .messageCountCache)
    }
}
