import SwiftUI
import MLX

@main
struct HiyoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = HiyoState()
    
    init() {
        // Initialize MLX GPU
        MLX.GPU.set(cacheLimit: 1024 * 1024 * 1024) // 1GB cache
        MLX.GPU.set(memoryLimit: 4 * 1024 * 1024 * 1024) // 4GB limit
        
        // Security checks
        CodeIntegrity.enforceIntegrity()
    }
    
    var body: some Scene {
        WindowGroup("Hiyo") {
            ContentView()
                .frame(minWidth: 900, minHeight: 600)
                .environmentObject(appState)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unifiedCompact(showsTitle: true))
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Conversation") {
                    SecureNotification.post(name: .newConversation)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        
        Settings {
            MLXSettingsView()
                .frame(minWidth: 600, minHeight: 500)
                .environmentObject(appState)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first {
            window.titlebarAppearsTransparent = true
            window.styleMask.insert(.fullSizeContentView)
        }
    }
}

class HiyoState: ObservableObject {
    @Published var selectedModel: String = "mlx-community/Llama-3.2-3B-Instruct-4bit"
    @Published var isSidebarVisible: Bool = true
    @Published var gpuUsage: Double = 0.0
    @Published var memoryUsage: Double = 0.0
}
