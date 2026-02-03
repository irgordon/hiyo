//
//  HiyoApp.swift
//  Hiyo
//
//  Local Intelligence Powered by You.
//

import SwiftUI
import AppKit
import MLX

@main
struct HiyoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = HiyoState()
    
    init() {
        // Initialize MLX GPU with sensible defaults
        MLX.GPU.set(cacheLimit: 1024 * 1024 * 1024) // 1GB cache
        MLX.GPU.set(memoryLimit: 4 * 1024 * 1024 * 1024) // 4GB limit
        
        // Security checks
        CodeIntegrity.enforceIntegrity()
        try? SecureFileManager.verifyContainerIntegrity()
        
        // Set default model on first launch
        if UserDefaults.standard.object(forKey: "selectedModel") == nil {
            UserDefaults.standard.set("mlx-community/Llama-3.2-3B-Instruct-4bit", forKey: "selectedModel")
        }
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
                
                Button("New Window") {
                    NSApp.sendAction(#selector(NSResponder.newWindowForTab(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
            
            CommandMenu("Conversation") {
                Button("Clear History") {
                    SecureNotification.post(name: .clearConversation)
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
                    // Open help
                }
                .keyboardShortcut("?", modifiers: .command)
                
                Divider()
                
                Button("Local AI Guide") {
                    NSWorkspace.shared.open(URL(string: "https://github.com/ml-explore/mlx-lm")!)
                }
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
        // Configure unified title bar
        if let window = NSApplication.shared.windows.first {
            window.titlebarAppearsTransparent = true
            window.styleMask.insert(.fullSizeContentView)
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            NSApp.sendAction(#selector(NSResponder.newWindowForTab(_:)), to: nil, from: nil)
        }
        return true
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up MLX
        MLX.GPU.clearCache()
    }
}
