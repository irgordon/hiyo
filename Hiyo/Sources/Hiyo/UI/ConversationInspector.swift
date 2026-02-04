import SwiftUI

@MainActor
struct ConversationInspector: View {
    @Environment(NavigationCoordinator.self) var nav
    @Bindable var chat: Chat
    var provider: MLXProvider

    var body: some View {
        Text("Inspector Stub for \(chat.title)")
    }
}
