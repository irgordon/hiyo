//
//  ContentView.swift
//  Hiyo
//
//  Main three-column layout with sidebar, chat, and inspector.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: HiyoState
    @StateObject private var store = try! HiyoStore()
    @StateObject private var provider = MLXProvider()
    
    var body: some View {
        NavigationSplitView(columnVisibility: $appState.isSidebarVisible) {
            // MARK: Sidebar
            ConversationSidebar(store: store, provider: provider)
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } content: {
            // MARK: Content
            if let chat = store.currentChat {
                ChatView(chat: chat, store: store, provider: provider)
            } else {
                HiyoWelcomeView(provider: provider)
            }
        } detail: {
            // MARK: Inspector
            if let chat = store.currentChat {
                ConversationInspector(chat: chat, provider: provider)
                    .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button(action: { appState.isSidebarVisible.toggle() }) {
                    Image(systemName: "sidebar.left")
                }
                .help("Toggle Sidebar")
                
                Button(action: { createNewChat() }) {
                    Image(systemName: "square.and.pencil")
                }
                .help("New Conversation")
            }
            
            ToolbarItemGroup(placement: .principal) {
                if provider.isAvailable {
                    ModelPicker(selectedModel: $appState.selectedModel, models: provider.availableModels)
                        .frame(width: 220)
                }
            }
            
            ToolbarItemGroup(placement: .automatic) {
                if provider.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 20)
                }
                
                ConnectionStatusBadge(provider: provider)
                
                Menu {
                    Button("Export as Text...") { exportAsText() }
                    Button("Export as JSON...") { exportAsJSON() }
                    Divider()
                    Button("Print...") { printConversation() }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .menuStyle(.borderedButton)
                .disabled(store.currentChat == nil)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .newConversation)) { _ in
            createNewChat()
        }
        .onReceive(NotificationCenter.default.publisher(for: .clearConversation)) { _ in
            clearCurrentChat()
        }
        .onChange(of: appState.selectedModel) { newModel in
            Task {
                try? await provider.loadModel(newModel)
            }
        }
    }
    
    private func createNewChat() {
        let chat = store.createChat(title: "New Chat", model: appState.selectedModel)
        NotificationCenter.default.post(name: .focusInputField, object: nil)
        
        // Auto-load model if needed
        if provider.currentModel != appState.selectedModel {
            Task {
                try? await provider.loadModel(appState.selectedModel)
            }
        }
    }
    
    private func clearCurrentChat() {
        if let chat = store.currentChat {
            store.clearMessages(in: chat)
        }
    }
    
    private func exportAsText() {
        NotificationCenter.default.post(name: .exportConversation, object: "txt")
    }
    
    private func exportAsJSON() {
        NotificationCenter.default.post(name: .exportConversation, object: "json")
    }
    
    private func printConversation() {
        // Implementation for print dialog
    }
}

struct ConnectionStatusBadge: View {
    @ObservedObject var provider: MLXProvider
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .cornerRadius(6)
    }
    
    private var statusColor: Color {
        if provider.isLoading { return .orange }
        return provider.isAvailable ? .green : .red
    }
    
    private var statusText: String {
        if provider.isLoading { return "Loading" }
        return provider.isAvailable ? "Ready" : "Offline"
    }
}
