//
//  HiyoApp.swift
//  Hiyo
//
//  Local Intelligence Powered by You.
//

import SwiftUI
import AppKit
import MLX

// MARK: - UserDefaults Keys

enum DefaultsKey {
    static let selectedModel = "selectedModel"
}

// MARK: - HiyoApp

@main
struct HiyoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appState = HiyoState()

    @State private var store: HiyoStore
    @State private var provider: MLXProvider
    @State private var nav: NavigationCoordinator

    init() {
        SecureMLX.configureSafeLimits()
        enforceSecurityIntegrity()
        configureDefaults()

        // Initialize store and coordinator
        do {
            let localStore = try HiyoStore()
            let localProvider = MLXProvider()
            _store = State(initialValue: localStore)
            _provider = State(initialValue: localProvider)
            _nav = State(initialValue: NavigationCoordinator(store: localStore, provider: localProvider))
        } catch {
            fatalError("Failed to initialize HiyoStore: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup("Hiyo") {
            ContentView()
                .frame(minWidth: 900, minHeight: 600)
                .environment(appState)
                .environment(store)
                .environment(provider)
                .environment(nav)
                .background(WindowReader { window in
                    appDelegate.mainWindow = window
                })
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unifiedCompact(showsTitle: true))
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Conversation") {
                    nav.createNewChat()
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("New Window") {
                    NSApp.sendAction(#selector(NSResponder.newWindowForTab(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }

            CommandMenu("Conversation") {
                Button("Clear History") {
                    if let chat = nav.selectedChat {
                        store.clearMessages(in: chat)
                    }
                }
                .keyboardShortcut("k", modifiers: [.command, .shift])

                Divider()

                Button("Export Conversation...") {
                    SecureNotification.post(name: .exportConversation)
                }
                .keyboardShortcut("e", modifiers: .command)
            }

            CommandMenu("Help") {
                Button("Hiyo Help") {
                    // Open local help or documentation window
                }
                .keyboardShortcut("?", modifiers: .command)

                Divider()

                Button("Local AI Guide") {
                    openLocalAIGuide()
                }
            }
        }

        Settings {
            MLXSettingsView()
                .frame(minWidth: 600, minHeight: 500)
                .environment(appState)
        }
    }

    // MARK: - Configuration

    private func enforceSecurityIntegrity() {
        CodeIntegrity.enforceIntegrity()

        do {
            try SecureFileManager.verifyContainerIntegrity()
        } catch {
            // Privacy-safe logging; consider failing fast if integrity is critical.
            NSLog("Container integrity verification failed: \(error.localizedDescription)")
        }
    }

    private func configureDefaults() {
        let defaults = UserDefaults.standard

        if defaults.object(forKey: DefaultsKey.selectedModel) == nil {
            defaults.set(
                "mlx-community/Llama-3.2-3B-Instruct-4bit",
                forKey: DefaultsKey.selectedModel
            )
        }
    }

    private func openLocalAIGuide() {
        guard let url = URL(string: "https://github.com/ml-explore/mlx-lm") else {
            assertionFailure("Invalid URL for Local AI Guide")
            return
        }
        NSWorkspace.shared.open(url)
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate {
    weak var mainWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureMainWindowAppearance()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            NSApp.sendAction(#selector(NSResponder.newWindowForTab(_:)), to: nil, from: nil)
        }
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Clean up MLX and any cached GPU resources
        MLX.GPU.clearCache()
    }

    private func configureMainWindowAppearance() {
        guard let window = mainWindow else { return }
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
    }
}

// MARK: - WindowReader

/// A helper view to capture the NSWindow created by the SwiftUI WindowGroup.
struct WindowReader: NSViewRepresentable {
    let onResolve: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                onResolve(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
