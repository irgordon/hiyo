//
//  Constants.swift
//  Hiyo
//
//  App-wide constants and configuration.
//

import Foundation

// MARK: - App Information

enum AppInfo {
    static let name = "Hiyo"
    static let slogan = "Local Intelligence Powered by You."
    static let bundleIdentifier = "ai.hiyo.mac"
    static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    static var fullVersion: String {
        "\(version) (\(build))"
    }
}

// MARK: - UI Constants

enum UIConstants {
    // Window sizes
    static let minWindowWidth: CGFloat = 900
    static let minWindowHeight: CGFloat = 600
    static let defaultWindowWidth: CGFloat = 1200
    static let defaultWindowHeight: CGFloat = 800
    
    // Sidebar
    static let sidebarMinWidth: CGFloat = 220
    static let sidebarIdealWidth: CGFloat = 260
    static let sidebarMaxWidth: CGFloat = 320
    
    // Inspector
    static let inspectorMinWidth: CGFloat = 200
    static let inspectorIdealWidth: CGFloat = 240
    static let inspectorMaxWidth: CGFloat = 300
    
    // Chat
    static let maxMessageWidth: CGFloat = 700
    static let inputMinHeight: CGFloat = 36
    static let inputMaxHeight: CGFloat = 120
    
    // Spacing
    static let defaultPadding: CGFloat = 16
    static let tightPadding: CGFloat = 8
    static let loosePadding: CGFloat = 24
}

// MARK: - Security Limits

enum SecurityLimits {
    // Input/output
    static let maxInputLength = 10000
    static let maxOutputLength = 50000
    
    // Rate limiting
    static let maxRequestsPerSecond = 10
    static let maxRequestsPerMinute = 60
    
    // Tokens
    static let maxContextTokens = 16384
    static let defaultMaxTokens = 4096
    static let maxConcurrentTokens = 10000
    
    // Memory
    static let maxMemoryUsageMB: UInt64 = 8192 // 8GB
    static let defaultCacheLimitMB: UInt64 = 1024 // 1GB
    static let defaultMemoryLimitMB: UInt64 = 4096 // 4GB
    
    // File
    static let maxExportFileSize = 100 * 1024 * 1024 // 100MB
    static let secureDeleteMaxSize = 100 * 1024 * 1024 // 100MB
}

// MARK: - MLX Configuration

enum MLXConfig {
    // Default models
    static let defaultModel = "mlx-community/Llama-3.2-3B-Instruct-4bit"
    
    // Model registry
    static let recommendedModels = [
        "mlx-community/Llama-3.2-1B-Instruct-4bit",
        "mlx-community/Llama-3.2-3B-Instruct-4bit",
        "mlx-community/Mistral-7B-Instruct-v0.3-4bit",
        "mlx-community/Phi-3-mini-4k-instruct-4bit",
        "mlx-community/Qwen2.5-7B-Instruct-4bit",
        "mlx-community/CodeLlama-7B-Instruct-4bit"
    ]
    
    // Generation defaults
    static let defaultTemperature: Float = 0.7
    static let defaultTopP: Float = 0.9
    static let defaultMaxTokens = 1024
    static let defaultContextLength = 4096
    
    // Performance
    static let streamingUpdateInterval: TimeInterval = 0.05 // 20fps
}

// MARK: - Storage Keys

enum StorageKeys {
    // UserDefaults
    static let selectedModel = "selectedModel"
    static let startupAction = "startupAction"
    static let theme = "theme"
    static let fontSize = "fontSize"
    static let storeHistory = "storeHistory"
    static let encryptExports = "encryptExports"
    static let temperature = "temperature"
    static let maxTokens = "maxTokens"
    static let contextLength = "contextLength"
    static let topP = "topP"
    static let gpuCacheLimit = "gpuCacheLimit"
    
    // Keychain
    static let encryptionKey = "hiyo.encryptionKey"
    
    // File paths
    static let conversationsDirectory = "Conversations"
    static let modelsCacheDirectory = "Models"
    static let exportsDirectory = "Exports"
}

// MARK: - Notification Names

extension Notification.Name {
    // App events
    static let hiyoNewConversation = Notification.Name("hiyo.newConversation")
    static let hiyoClearConversation = Notification.Name("hiyo.clearConversation")
    static let hiyoExportConversation = Notification.Name("hiyo.exportConversation")
    static let hiyoFocusInput = Notification.Name("hiyo.focusInput")
    
    // Model events
    static let hiyoModelLoaded = Notification.Name("hiyo.modelLoaded")
    static let hiyoModelUnloaded = Notification.Name("hiyo.modelUnloaded")
    static let hiyoGenerationStarted = Notification.Name("hiyo.generationStarted")
    static let hiyoGenerationCompleted = Notification.Name("hiyo.generationCompleted")
}

// MARK: - URLs

enum AppURLs {
    static let website = URL(string: "https://hiyo.ai")!
    static let documentation = URL(string: "https://docs.hiyo.ai")!
    static let github = URL(string: "https://github.com/hiyoai/hiyo")!
    static let mlxCommunity = URL(string: "https://huggingface.co/mlx-community")!
    static let ollama = URL(string: "https://ollama.ai")!
    static let privacyPolicy = URL(string: "https://hiyo.ai/privacy")!
}

// MARK: - Error Messages

enum ErrorMessages {
    static let genericError = "Something went wrong. Please try again."
    static let modelNotLoaded = "Please select and load a model in Settings."
    static let contextTooLong = "This conversation is too long. Start a new chat."
    static let memoryLimit = "Your Mac is running low on memory. Close other apps and try again."
    static let rateLimited = "Please slow down. Too many requests."
    static let exportFailed = "Failed to export conversation. Please try again."
    static let importFailed = "Failed to import file. It may be corrupted or incompatible."
}

// MARK: - Accessibility Labels

enum AccessibilityLabels {
    static let newConversation = "New conversation"
    static let sendMessage = "Send message"
    static let stopGeneration = "Stop generating"
    static let toggleSidebar = "Toggle sidebar"
    static let searchConversations = "Search conversations"
    static let modelSelector = "Select AI model"
    static let exportConversation = "Export conversation"
    static let deleteConversation = "Delete conversation"
    static let messageInput = "Message input field"
}
