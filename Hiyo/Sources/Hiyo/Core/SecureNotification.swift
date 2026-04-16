//
//  SecureNotification.swift
//  Hiyo
//
//  Internal notification system without XPC/distributed notifications.
//

import Foundation

/// Secure notification system using only local NotificationCenter

// MARK: - Notification Names

extension Notification.Name {
    // App lifecycle
    static let hiyoNewConversation = Notification.Name("hiyo.newConversation")
    static let hiyoClearConversation = Notification.Name("hiyo.clearConversation")
    static let hiyoExportConversation = Notification.Name("hiyo.exportConversation")
    static let hiyoFocusInput = Notification.Name("hiyo.focusInput")
    
    // Model events
    static let hiyoModelLoaded = Notification.Name("hiyo.modelLoaded")
    static let hiyoModelUnloaded = Notification.Name("hiyo.modelUnloaded")
    static let hiyoModelLoadFailed = Notification.Name("hiyo.modelLoadFailed")
    
    // Generation events
    static let hiyoGenerationStarted = Notification.Name("hiyo.generationStarted")
    static let hiyoGenerationCompleted = Notification.Name("hiyo.generationCompleted")
    static let hiyoGenerationCancelled = Notification.Name("hiyo.generationCancelled")
}
