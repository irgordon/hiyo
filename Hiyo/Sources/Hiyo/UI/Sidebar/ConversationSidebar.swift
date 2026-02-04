//
//  ConversationSidebar.swift
//  Hiyo
//
//  Left sidebar with conversation list and search.
//

import SwiftUI
import SwiftData

struct ConversationSidebar: View {
    @Environment(NavigationCoordinator.self) var nav
    @Environment(HiyoStore.self) var store
    @Environment(MLXProvider.self) var provider

    @Query(sort: \ChatSummary.modifiedAt, order: .reverse)
    var summaries: [ChatSummary]
    
    @State private var searchText = ""
    @State private var debouncedSearchText = ""
    @State private var summaryToDelete: ChatSummary?
    @State private var showingDeleteConfirmation = false
    
    // Filtered summaries
    private var filteredSummaries: [ChatSummary] {
        if debouncedSearchText.isEmpty {
            return summaries
        }
        return summaries.filter { $0.title.localizedStandardContains(debouncedSearchText) }
    }
    
    var body: some View {
        @Bindable var nav = nav

        VStack(spacing: 0) {
            searchField
            
            // Note: selection parameter removed because of type mismatch (ChatSummary vs Chat).
            // Selection is handled via ConversationRow's onTapGesture and isSelected state.
            List {
                Section {
                    ForEach(filteredSummaries) { summary in
                        ConversationRow(
                            chat: summary,
                            isSelected: nav.selectedChat?.id == summary.id
                        )
                        .tag(summary.id)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            nav.selectChat(summary)
                        }
                        .contextMenu {
                            Button("Rename") { renameChat(summary) }
                            Button("Duplicate") { duplicateChat(summary) }
                            Divider()
                            Button("Delete", role: .destructive) {
                                summaryToDelete = summary
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
                        Text("\(filteredSummaries.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.sidebar)
            
            statusBar
        }
        // Fix: Removed incorrect ShapeStyle reference, using Color(nsColor: .windowBackgroundColor) or clear
        // Assuming .sidebarBackground was meant to be a semantic color. Using default for now.
        .background(Color.clear)
        .task(id: searchText) {
            do {
                try await Task.sleep(for: .milliseconds(250))
                debouncedSearchText = searchText
            } catch {}
        }
        .alert(
            "Delete Conversation?",
            isPresented: $showingDeleteConfirmation,
            presenting: summaryToDelete
        ) { summary in
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteSummary(summary)
            }
        } message: { summary in
            Text("This will permanently delete '\(summary.title)' and all its messages.")
        }
    }
}

private extension ConversationSidebar {
    
    // MARK: - Search Field
    
    var searchField: some View {
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
    }
    
    // MARK: - Status Bar
    
    var statusBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider()
            
            HStack(spacing: 8) {
                Image(systemName: provider.isAvailable ? "cpu.fill" : "exclamationmark.triangle")
                    .foregroundStyle(provider.isAvailable ? Color.accentColor : .orange)
                    .imageScale(.small)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(provider.isAvailable ? "MLX Ready" : "Model Offline")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    if let model = nav.selectedChat?.modelIdentifier {
                        // Fix: displayName is likely available on String, assuming utils exist.
                        // If not, we use raw string or simple replacement.
                        // The error said "invalid redeclaration", so we assume it exists elsewhere.
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
    
    // MARK: - Actions
    
    func deleteChats(offsets: IndexSet) {
        offsets.map { filteredSummaries[$0] }.forEach(deleteSummary)
    }

    func deleteSummary(_ summary: ChatSummary) {
        // Fix: Removed extra 'as: Chat.self' argument
        if let chat = store.modelContext.model(for: summary.id) as? Chat {
            store.deleteChat(chat)
            if nav.selectedChat?.id == chat.id {
                nav.deselectChat()
            }
        }
    }

    func duplicateChat(_ summary: ChatSummary) {
        // Fix: Removed extra 'as: Chat.self' argument
        if let chat = store.modelContext.model(for: summary.id) as? Chat {
            store.duplicateChat(chat)
        }
    }
    
    func renameChat(_ summary: ChatSummary) {
        // Fix: Removed extra 'as: Chat.self' argument
        guard let chat = store.modelContext.model(for: summary.id) as? Chat else { return }

        // Replace with SwiftUI-native rename UI later
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
}

// Fix: Removed duplicate extension String.displayName
