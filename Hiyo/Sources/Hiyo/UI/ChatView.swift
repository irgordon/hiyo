import SwiftUI

struct ChatView: View {
    @Bindable var chat: Chat
    var store: HiyoStore
    var provider: MLXProvider

    var body: some View {
        Text("Chat View Stub for \(chat.title)")
    }
}
