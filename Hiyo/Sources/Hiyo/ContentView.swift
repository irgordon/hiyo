//
//  ContentView.swift
//  Hiyo
//
//  Main three-column layout with sidebar, chat, and inspector.
//

import SwiftUI

struct ContentView: View {
    @Environment(NavigationCoordinator.self) var nav
    @Environment(HiyoState.self) var appState
    @Environment(HiyoStore.self) var store
    @Environment(MLXProvider.self) var provider

    // Binding adapter for column visibility since NavigationSplitView expects Binding<NavigationSplitViewVisibility>
    // but nav.isSidebarVisible is a Bool. We can map it roughly or assume double column for now.
    // However, standard sidebar toggling usually uses columnVisibility.
    // For simplicity, let's keep binding to appState as before if that controls UI persistence,
    // OR migrate to nav fully if we want nav to control it. The requirement says nav.
    // Let's use a computed binding.
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(
            columnVisibility: $columnVisibility,
            sidebar: {
                // MARK: Sidebar
                ConversationSidebar()
                    .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
                    .toolbar(removing: .sidebarToggle) // We implement our own
            },
            content: {
                // MARK: Content
                if let chat = nav.selectedChat {
                    ChatView(chat: chat, store: store, provider: provider)
                } else {
                    HiyoWelcomeView(provider: provider)
                }
            },
            detail: {
                // MARK: Inspector
                if nav.isInspectorVisible, let chat = nav.selectedChat {
                    ConversationInspector(chat: chat, provider: provider)
                        .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
                }
            }
        )
        .navigationSplitViewStyle(.balanced)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button(action: {
                    withAnimation {
                        if columnVisibility == .detailOnly {
                            columnVisibility = .all
                        } else {
                            columnVisibility = .detailOnly // Collapse sidebar
                        }
                        nav.toggleSidebar()
                    }
                }) {
                    Image(systemName: "sidebar.left")
                }
                .help("Toggle Sidebar")

                Button(action: { nav.createNewChat() }) {
                    Image(systemName: "square.and.pencil")
                }
                .help("New Conversation")
            }

            ToolbarItemGroup(placement: .principal) {
                if provider.isAvailable {
                    ModelPicker(
                        selectedModel: $appState.selectedModel,
                        models: provider.availableModels
                    )
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

                Button(action: {
                    withAnimation {
                        nav.toggleInspector()
                    }
                }) {
                    Image(systemName: "sidebar.right")
                        .foregroundStyle(nav.isInspectorVisible ? .accentColor : .secondary)
                }
                .disabled(nav.selectedChat == nil)
                .help("Toggle Inspector")

                Menu(content: {
                    Button("Export as Text...") { exportAsText() }
                    Button("Export as JSON...") { exportAsJSON() }
                    Divider()
                    Button("Print...") { printConversation() }
                }, label: {
                    Image(systemName: "square.and.arrow.up")
                })
                .menuStyle(.borderedButton)
                .disabled(nav.selectedChat == nil)
            }
        }
        .task {
            for await _ in NotificationCenter.default.notifications(named: .newConversation) {
                nav.createNewChat()
            }
        }
        .task {
            for await _ in NotificationCenter.default.notifications(named: .clearConversation) {
                if let chat = nav.selectedChat {
                    store.clearMessages(in: chat)
                }
            }
        }
        .onChange(of: appState.selectedModel) { _, newModel in
            Task {
                do {
                    try await provider.loadModel(newModel)
                } catch {
                    NSLog("Model load failed for \(newModel): \(error.localizedDescription)")
                    // Optionally surface a user-facing, non-technical error here.
                }
            }
        }
        .onChange(of: nav.isSidebarVisible) { _, isVisible in
            // Sync nav state to split view
             withAnimation {
                columnVisibility = isVisible ? .all : .detailOnly
            }
        }
    }

    // MARK: - Actions

    private func exportAsText() {
        // Downstream handlers must ensure sensitive content is handled safely.
        NotificationCenter.default.post(name: .exportConversation, object: "txt")
    }

    private func exportAsJSON() {
        // Downstream handlers must ensure sensitive content is handled safely.
        NotificationCenter.default.post(name: .exportConversation, object: "json")
    }

    private func printConversation() {
        // Implementation for print dialog.
        // Ensure printed content respects user privacy and does not log raw data.
    }
}

struct ConnectionStatusBadge: View {
    var provider: MLXProvider

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
