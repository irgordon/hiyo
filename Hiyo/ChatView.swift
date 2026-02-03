import SwiftUI

struct ChatView: View {
    let chat: Chat
    @ObservedObject var store: HiyoStore
    @ObservedObject var provider: MLXProvider
    
    @State private var inputText = ""
    @State private var isGenerating = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Model status bar
            if provider.isLoading {
                LoadingProgressBar(progress: provider.loadingProgress, model: provider.currentModel)
            }
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(chat.messages) { message in
                            MessageView(message: message)
                                .id(message.id)
                        }
                        
                        if isGenerating {
                            TypingIndicator()
                                .id("typing")
                        }
                    }
                    .padding(.vertical, 16)
                }
                .background(.background)
            }
            
            // Input area
            VStack(spacing: 0) {
                HStack(alignment: .bottom, spacing: 12) {
                    TextEditor(text: $inputText)
                        .font(.body)
                        .frame(minHeight: 36, maxHeight: 120)
                        .scrollContentBackground(.hidden)
                        .focused($isInputFocused)
                        .onSubmit { sendMessage() }
                    
                    Button(action: sendMessage) {
                        Image(systemName: isGenerating ? "stop.fill" : "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .symbolRenderingMode(.hierarchical)
                    }
                    .buttonStyle(.plain)
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isGenerating)
                }
                .padding(12)
                .background(.textBackgroundColor)
                .cornerRadius(12)
                .padding()
                
                // GPU Status
                HStack {
                    Label("\(Int(provider.memoryUsage * 1000)) MB", systemImage: "memorychip")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if isGenerating {
                        Button("Stop") {
                            // Cancel generation
                        }
                        .font(.caption)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .background(.ultraThinMaterial)
        }
        .navigationTitle(chat.title)
        .navigationSubtitle(provider.currentModel)
        .task {
            // Auto-load model if not loaded
            if !provider.isAvailable {
                try? await provider.loadModel(chat.modelIdentifier)
            }
        }
    }
    
    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let content = inputText
        inputText = ""
        isGenerating = true
        
        store.addMessage(content, role: .user, to: chat)
        
        Task {
            do {
                let messages = chat.messages.map { msg in
                    Message(role: msg.role.rawValue, content: msg.content)
                }
                
                var assistantContent = ""
                let assistantMessage = store.addMessage("", role: .assistant, to: chat)
                
                let stream = try await provider.generate(
                    messages: messages,
                    parameters: GenerationParameters(temperature: 0.7)
                )
                
                for try await token in stream {
                    assistantContent += token
                    assistantMessage.content = assistantContent
                }
                try? store.modelContext.save()
            } catch {
                store.addMessage("Error: \(error.localizedDescription)", role: .system, to: chat)
            }
            
            isGenerating = false
        }
    }
}

struct LoadingProgressBar: View {
    let progress: Double
    let model: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Loading \(model)")
                    .font(.caption)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption)
            }
            ProgressView(value: progress)
                .progressViewStyle(.linear)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.thinMaterial)
    }
}
