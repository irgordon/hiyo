//
//  ChatSummary.swift
//  Hiyo
//
//  Lightweight projection for list views (no relationship faults).
//

import Foundation
import SwiftData

@Model
final class ChatSummary {
    @Attribute(.unique) var id: UUID
    var title: String
    var modelIdentifier: String
    var lastMessagePreview: String?
    var messageCount: Int
    var modifiedAt: Date

    init(
        id: UUID,
        title: String,
        modelIdentifier: String,
        lastMessagePreview: String?,
        messageCount: Int,
        modifiedAt: Date
    ) {
        self.id = id
        self.title = title
        self.modelIdentifier = modelIdentifier
        self.lastMessagePreview = lastMessagePreview
        self.messageCount = messageCount
        self.modifiedAt = modifiedAt
    }
}
