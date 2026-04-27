sed -i 's/store.modelContext.model(for: summary.id, as: Chat.self)/store.modelContext.model(for: summary.id) as? Chat/g' Hiyo/Sources/Hiyo/UI/Sidebar/ConversationSidebar.swift
