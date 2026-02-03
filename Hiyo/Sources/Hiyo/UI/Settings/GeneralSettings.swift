//
//  GeneralSettings.swift
//  Hiyo
//
//  Appearance, behavior, and general preferences.
//

import SwiftUI

struct GeneralSettings: View {
    @AppStorage(StorageKeys.startupAction) private var startupAction = "newChat"
    @AppStorage(StorageKeys.theme) private var theme = "system"
    @AppStorage(StorageKeys.fontSize) private var fontSize = 13
    
    var body: some View {
        Form {
            Section("Startup") {
                Picker("On Launch:", selection: $startupAction) {
                    Text("Start New Conversation").tag("newChat")
                    Text("Restore Last Session").tag("restore")
                    Text("Show Welcome Screen").tag("welcome")
                }
                .pickerStyle(.radioGroup)
            }
            
            Section("Appearance") {
                Picker("Theme:", selection: $theme) {
                    Text("Match System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Font Size")
                        Spacer()
                        Text("\(fontSize) pt")
                            .monospacedDigit()
                    }
                    
                    Slider(value: .init(
                        get: { Double(fontSize) },
                        set: { fontSize = Int($0) }
                    ), in: 11...18, step: 1)
                }
            }
            
            Section("Behavior") {
                Toggle("Show Token Count", isOn: .constant(true))
                Toggle("Auto-save Conversations", isOn: .constant(true))
                Toggle("Sound Effects", isOn: .constant(false))
            }
            
            Section("About") {
                LabeledContent("Version", value: AppInfo.fullVersion)
                LabeledContent("Build Date", value: buildDate)
                
                HStack(spacing: 16) {
                    Button("Website") {
                        NSWorkspace.shared.open(AppURLs.website)
                    }
                    .buttonStyle(.link)
                    
                    Button("GitHub") {
                        NSWorkspace.shared.open(AppURLs.github)
                    }
                    .buttonStyle(.link)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("General")
    }
    
    private var buildDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: Date())
    }
}
