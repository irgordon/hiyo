//
//  Chat+SummaryProjection.swift
//  Hiyo
//

import SwiftData

extension Chat {
    /// Lightweight projection for list views.
    static var summaryProjection: SwiftData.Projection<Chat, ChatSummary> {
        SwiftData.Projection(
            ChatSummary.self,
            \.id,
            \.title,
            \.modelIdentifier,
            \.lastMessagePreview,
            \.messageCountCache,
            \.modifiedAt
        ) { id, title, modelIdentifier, preview, count, modified in
            ChatSummary(
                id: id,
                title: title,
                modelIdentifier: modelIdentifier,
                lastMessagePreview: preview,
                messageCount: count,
                modifiedAt: modified
            )
        }
    }
}
