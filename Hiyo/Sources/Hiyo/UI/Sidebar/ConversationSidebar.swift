//
//  ConversationSidebar.swift
//  Hiyo
//
//  Left sidebar with conversation list and search.
//

import SwiftUI

struct ConversationSidebar: View {
    @ObservedObject var store: HiyoStore
    @ObservedObject var provider: MLXProvider
    @State private var searchText = ""
    @State private var showingDeleteConfirmation = false
    @State private var chatToDelete: Chat?
    
    var filteredChats: [Chat] {
        store.searchChats(query: searchText)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(8)
            .background(.secondary.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            // Conversation list
            List(selection: $store.currentChat) {
                Section {
                    ForEach(filteredChats) { chat in
                        ConversationRow(
                            chat: chat,
                            isSelected: store.currentChat?.id == chat.id
                        )
                        .tag(chat)
                        .contextMenu {
                            Button("Rename") { renameChat(chat) }
                            Button("Duplicate") { duplicateChat(chat) }
                            Divider()
                            Button("Delete", role: .destructive) {
                                chatToDelete = chat
                                showingDeleteConfirmation = true
                            }
                        }
                    }
                    .onDelete(perform: deleteChats)
                } header: {
                    HStack {
                        Text("Conversations")
                            .font(.caption)
                            .textCase(.uppercase)
                        Spacer()
                        Text("\(filteredChats.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.sidebar)
            
            // Bottom status bar
            VStack(alignment: .leading, spacing: 6) {
                Divider()
                
                HStack(spacing: 8) {
                    Image(systemName: provider.isAvailable ? "cpu.fill" : "exclamationmark.triangle")
                        .foregroundStyle(provider.isAvailable ? .accent : .orange)
                        .imageScale(.small)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(provider.isAvailable ? "MLX Ready" : "Model Offline")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        if let model = store.currentChat?.modelIdentifier {
                            Text(model.displayName)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                }
                
                if provider.memoryUsage > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "memorychip")
                            .font(.caption2)
                        Text("\(Int(provider.memoryUsage * 1024)) MB")
                            .font(.caption2)
                        Spacer()
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
        }
        .background(.sidebarBackground)
        .alert("Delete Conversation?", isPresented: $showingDeleteConfirmation, presenting: chatToDelete) { chat in
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                store.deleteChat(chat)
            }
        } message: { chat in
            Text("This will permanently delete '\(chat.title)' and all its messages.")
        }
    }
    
    private func deleteChats(offsets: IndexSet) {
        offsets.map { filteredChats[$0] }.forEach(store.deleteChat)
    }
    
    private func renameChat(_ chat: Chat) {
        // Present rename dialog
        let alert = NSAlert()
        alert.messageText = "Rename Conversation"
        alert.informativeText = "Enter a new name:"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Rename")
        alert.addButton(withTitle: "Cancel")
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.stringValue = chat.title
        alert.accessoryView = textField
        
        if alert.runModal() == .alertFirstButtonReturn {
            chat.title = textField.stringValue
            try? store.modelContext.save()
        }
    }
    
    private func duplicateChat(_ chat: Chat) {
        store.duplicateChat(chat)
    }
}

extension String {
    var displayName: String {
        self.replacingOccurrences(of: "mlx-community/", with: "")
            .replacingOccurrences(of: "-Instruct", with: "")
            .replacingOccurrences(of: "-4bit", with: "")
    }
}
