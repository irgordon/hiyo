//
//  ConversationRow.swift
//  Hiyo
//
//  Individual conversation list item.
//  Updated to use Chat for zero‑fault list performance.
//

import SwiftUI

struct ConversationRow: View {
    let chat: Chat
    let isSelected: Bool
    
    private var iconName: String {
        if chat.modelIdentifier.contains("code") {
            return "chevron.left.forwardslash.chevron.right"
        }
        if chat.modelIdentifier.contains("vision") || chat.modelIdentifier.contains("image") {
            return "eye"
        }
        return "bubble.left.fill"
    }
    
    /// Uses denormalized preview — never touches relationships.
    private var messagePreview: String {
        chat.lastMessagePreview ?? "No messages"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            
            // Model icon
            ZStack {
                Circle()
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: iconName)
                    .font(.system(size: 14))
                    .foregroundStyle(isSelected ? .accentColor : .secondary)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 3) {
                Text(chat.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                
                Text(messagePreview)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Timestamp + count
            VStack(alignment: .trailing, spacing: 2) {
                Text(chat.modifiedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                if chat.messageCount > 0 {
                    Text("\(chat.messageCount)")
                        .font(.caption2)
                        .foregroundStyle(.secondary.opacity(0.7))
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .background(isSelected ? Color.accentColor.opacity(0.08) : Color.clear)
        .cornerRadius(6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(chat.title), \(messagePreview), \(chat.messageCount) messages")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
