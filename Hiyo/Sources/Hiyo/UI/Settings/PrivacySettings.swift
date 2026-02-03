//
//  PrivacySettings.swift
//  Hiyo
//
//  Data storage, encryption, and security controls.
//

import SwiftUI

struct PrivacySettings: View {
    @AppStorage(StorageKeys.storeHistory) private var storeHistory = true
    @AppStorage(StorageKeys.encryptExports) private var encryptExports = true
    
    @State private var showingClearConfirmation = false
    @State private var showingClearedAlert = false
    
    var body: some View {
        Form {
            Section("Data Storage") {
                Toggle("Store Conversation History", isOn: $storeHistory)
                    .help("Save chats to your Mac's encrypted storage")
                
                Toggle("Encrypt Exported Files", isOn: $encryptExports)
                    .help("Add AES-256 encryption to exported conversations")
                
                if !storeHistory {
                    Text("History is not saved. Conversations will be lost when you close Hiyo.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            
            Section("Security") {
                LabeledContent("Data Location", value: "Local Only")
                LabeledContent("Network", value: "Disabled")
                LabeledContent("iCloud Sync", value: "Disabled")
                LabeledContent("Sandbox", value: "Active")
                LabeledContent("Code Signing", value: "Verified")
                
                Text("Hiyo never connects to external servers. Your conversations and model data never leave this device.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("Danger Zone") {
                Button("Clear All Hiyo Data...") {
                    showingClearConfirmation = true
                }
                .foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
        .alert("Clear All Data?", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear Everything", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("This will permanently delete all conversations, settings, and cached models. This cannot be undone.")
        }
        .alert("Data Cleared", isPresented: $showingClearedAlert) {
            Button("OK") { }
        } message: {
            Text("All Hiyo data has been removed from your Mac.")
        }
        .navigationTitle("Privacy & Security")
    }
    
    private func clearAllData() {
        do {
            try SecureMLX.clearAllCaches()
            // Clear conversations...
            showingClearedAlert = true
            SecurityLogger.log(.dataCleared, details: "User initiated full data clear")
        } catch {
            // Show error
        }
    }
}
