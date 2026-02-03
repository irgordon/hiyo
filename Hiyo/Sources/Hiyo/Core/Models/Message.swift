//
//  Message.swift
//  Hiyo
//
//  Individual message model for SwiftData.
//

import Foundation
import SwiftData

enum MessageRole: String, Codable {
    case system, user, assistant
}

@Model
final class Message {
    @Attribute(.unique) var id: UUID
    var content: String
    var role: MessageRole
    var timestamp: Date
    
    var tokensUsed: Int?
    var latencyMs: Double?
    
    // Relationship back to chat
    var chat: Chat?
    
    init(content: String, role: MessageRole) {
        self.id = UUID()
        self.content = content
        self.role = role
        self.timestamp = Date()
    }
    
    // MARK: - Computed Properties
    
    var isFromUser: Bool {
        role == .user
    }
    
    var isFromAssistant: Bool {
        role == .assistant
    }
    
    var isSystem: Bool {
        role == .system
    }
    
    var displayContent: String {
        // Sanitize for display
        content
            .replacingOccurrences(of: "\0", with: "")
            .normalizingLineEndings
    }
    
    var preview: String {
        let cleaned = content.strippingMarkdown
        return String(cleaned.prefix(100))
    }
    
    // MARK: - Formatting
    
    func formattedTimestamp(style: DateFormatter.Style = .short) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = style
        formatter.dateStyle = .none
        return formatter.string(from: timestamp)
    }
}

// MARK: - Codable Support

extension Message: Codable {
    enum CodingKeys: String, CodingKey {
        case id, content, role, timestamp, tokensUsed, latencyMs
    }
    
    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let content = try container.decode(String.self, forKey: .content)
        let role = try container.decode(MessageRole.self, forKey: .role)
        
        self.init(content: content, role: role)
        
        self.id = try container.decode(UUID.self, forKey: .id)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.tokensUsed = try container.decodeIfPresent(Int.self, forKey: .tokensUsed)
        self.latencyMs = try container.decodeIfPresent(Double.self, forKey: .latencyMs)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(role, forKey: .role)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(tokensUsed, forKey: .tokensUsed)
        try container.encode(latencyMs, forKey: .latencyMs)
    }
}
