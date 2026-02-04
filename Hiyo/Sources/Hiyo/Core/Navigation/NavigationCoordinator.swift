import SwiftUI
import SwiftData
import Observation

@MainActor
@Observable
final class NavigationCoordinator {

    // MARK: - Selection State

    /// The currently selected full Chat model.
    var selectedChat: Chat?

    /// Whether the inspector panel is visible.
    var isInspectorVisible: Bool = false

    /// Whether the sidebar is visible.
    var isSidebarVisible: Bool = true

    // MARK: - Dependencies

    let store: HiyoStore
    let provider: MLXProvider

    init(store: HiyoStore, provider: MLXProvider) {
        self.store = store
        self.provider = provider
    }

    // MARK: - Chat Selection

    /// Selects a chat from a ChatSummary projection.
    func selectChat(_ summary: ChatSummary) {
        if let fullChat = store.modelContext.model(for: summary.id, as: Chat.self) {
            selectedChat = fullChat
        }
    }

    func deselectChat() {
        selectedChat = nil
        isInspectorVisible = false
    }

    // MARK: - UI Toggles

    func toggleInspector() {
        guard selectedChat != nil else { return }
        isInspectorVisible.toggle()
    }

    func toggleSidebar() {
        isSidebarVisible.toggle()
    }

    // MARK: - Chat Lifecycle

    func createNewChat() {
        let newChat = store.createChat(
            title: "New Chat",
            model: provider.currentModel
        )
        selectedChat = newChat
        isSidebarVisible = true
    }

    func deleteSelectedChat() {
        guard let chat = selectedChat else { return }
        store.deleteChat(chat)
        deselectChat()
    }
}
