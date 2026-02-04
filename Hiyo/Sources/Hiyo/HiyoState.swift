//
//  HiyoState.swift
//  Hiyo
//
//  Global app state shared across views.
//

import SwiftUI
import Observation

// MARK: - UserDefaults Keys

enum DefaultsKey {
    static let selectedModel = "selectedModel"
    static let temperature = "temperature"
    static let maxTokens = "maxTokens"
}

// MARK: - HiyoState

@MainActor
@Observable
class HiyoState {
    // MARK: - UI State

    var selectedModel: String {
        didSet {
            UserDefaults.standard.set(selectedModel, forKey: DefaultsKey.selectedModel)
        }
    }

    var isSidebarVisible: Bool = true

    // MARK: - MLX Performance Metrics

    var gpuUsage: Double = 0.0
    var memoryUsage: Double = 0.0
    var isGenerating: Bool = false

    // MARK: - User Preferences

    var temperature: Double {
        didSet {
            UserDefaults.standard.set(temperature, forKey: DefaultsKey.temperature)
        }
    }

    var maxTokens: Int {
        didSet {
            UserDefaults.standard.set(maxTokens, forKey: DefaultsKey.maxTokens)
        }
    }

    // MARK: - Initialization

    init() {
        let defaults = UserDefaults.standard

        // Selected model
        if let storedModel = defaults.string(forKey: DefaultsKey.selectedModel) {
            self.selectedModel = storedModel
        } else {
            self.selectedModel = "mlx-community/Llama-3.2-3B-Instruct-4bit"
        }

        // Temperature
        if let storedTemp = defaults.object(forKey: DefaultsKey.temperature) as? Double {
            self.temperature = storedTemp
        } else {
            self.temperature = 0.7
        }

        // Max tokens
        if let storedMaxTokens = defaults.object(forKey: DefaultsKey.maxTokens) as? Int {
            self.maxTokens = storedMaxTokens
        } else {
            self.maxTokens = 1024
        }
    }

    // MARK: - Methods

    func updateGPUMetrics(activeMemory: Double, peakMemory: Double) {
        // For now, we only expose active memory usage.
        // If MLX exposes richer metrics, gpuUsage can be derived here.
        self.memoryUsage = activeMemory
        // self.gpuUsage = calculateGPUUsage(active: activeMemory, peak: peakMemory)
    }

    func resetToDefaults() {
        selectedModel = "mlx-community/Llama-3.2-3B-Instruct-4bit"
        temperature = 0.7
        maxTokens = 1024
        // Persistence is handled by didSet observers.
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

    @discardableResult
    static func observe(
        name: Notification.Name,
        object: AnyObject? = nil,
        using: @escaping (Notification) -> Void
    ) -> NSObjectProtocol {
        NotificationCenter.default.addObserver(
            forName: name,
            object: object,
            queue: .main,
            using: using
        )
    }

    static func remove(_ token: NSObjectProtocol) {
        NotificationCenter.default.removeObserver(token)
    }
}
