//
//  HiyoState.swift
//  Hiyo
//
//  Global app state shared across views.
//

import SwiftUI
import Combine

@MainActor
class HiyoState: ObservableObject {
    // MARK: - UI State
    
    @Published var selectedModel: String {
        didSet {
            UserDefaults.standard.set(selectedModel, forKey: "selectedModel")
        }
    }
    
    @Published var isSidebarVisible: Bool = true
    
    // MARK: - MLX Performance Metrics
    
    @Published var gpuUsage: Double = 0.0
    @Published var memoryUsage: Double = 0.0
    @Published var isGenerating: Bool = false
    
    // MARK: - User Preferences
    
    @Published var temperature: Double = 0.7
    @Published var maxTokens: Int = 1024
    
    // MARK: - Initialization
    
    init() {
        self.selectedModel = UserDefaults.standard.string(forKey: "selectedModel") 
            ?? "mlx-community/Llama-3.2-3B-Instruct-4bit"
        
        // Load saved preferences
        self.temperature = UserDefaults.standard.double(forKey: "temperature")
        if self.temperature == 0 { self.temperature = 0.7 }
        
        self.maxTokens = UserDefaults.standard.integer(forKey: "maxTokens")
        if self.maxTokens == 0 { self.maxTokens = 1024 }
    }
    
    // MARK: - Methods
    
    func updateGPUMetrics(activeMemory: Double, peakMemory: Double) {
        self.memoryUsage = activeMemory
        // GPU usage calculation would come from MLX metrics
    }
    
    func resetToDefaults() {
        selectedModel = "mlx-community/Llama-3.2-3B-Instruct-4bit"
        temperature = 0.7
        maxTokens = 1024
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let newConversation = Notification.Name("hiyo.newConversation")
    static let clearConversation = Notification.Name("hiyo.clearConversation")
    static let exportConversation = Notification.Name("hiyo.exportConversation")
    static let focusInputField = Notification.Name("hiyo.focusInputField")
}

// MARK: - Secure Notification System

enum SecureNotification {
    static func post(name: Notification.Name, object: Any? = nil) {
        NotificationCenter.default.post(name: name, object: object)
    }
    
    static func observe(name: Notification.Name, object: AnyObject? = nil, using: @escaping (Notification) -> Void) -> Any {
        NotificationCenter.default.addObserver(forName: name, object: object, queue: .main, using: using)
    }
}
