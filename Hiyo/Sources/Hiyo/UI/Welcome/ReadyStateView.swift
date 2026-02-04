//
//  ReadyStateView.swift
//  Hiyo
//
//  Welcome screen when MLX is ready to use.
//

import SwiftUI

struct ReadyStateView: View {
    @ObservedObject var provider: MLXProvider
    
    var body: some View {
        VStack(spacing: 20) {
            // Logo mark
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.accentColor.opacity(0.3), .accentColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.accentColor)
            }
            
            Text("Welcome to Hiyo")
                .font(.system(size: 32, weight: .bold))
            
            Text(AppInfo.slogan)
                .font(.title3)
                .foregroundStyle(.secondary)
            
            Text("Start a conversation with your local AI. Everything stays on your Mac — private, secure, and completely offline.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
                .padding(.horizontal)
            
            // Feature highlights
            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "bolt.fill", text: "Up to 2x faster than CPU inference")
                FeatureRow(icon: "memorychip", text: "Unified memory — no data copying")
                FeatureRow(icon: "lock.fill", text: "100% private, on-device only")
            }
            .frame(width: 340)
            .padding(.top, 16)
            
            // Model info or call to action
            if provider.currentModel == "None" {
                VStack(spacing: 16) {
                    Text("No model loaded")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    
                    Button("Select a Model to Start") {
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding(.top, 24)
            } else {
                VStack(spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("\(provider.currentModel.displayName) ready")
                            .font(.callout)
                    }
                    .foregroundStyle(.secondary)
                    
                    Button("Start New Conversation") {
                        NotificationCenter.default.post(name: .hiyoNewConversation, object: nil)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut("n", modifiers: .command)
                }
                .padding(.top, 24)
            }
            
            // Quick settings hint
            HStack(spacing: 4) {
                Text("Press")
                Text("⌘,")
                    .fontWeight(.semibold)
                Text("for Settings")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.top, 32)
        }
        .padding()
    }
}

extension String {
    var displayName: String {
        self.replacingOccurrences(of: "mlx-community/", with: "")
            .replacingOccurrences(of: "-Instruct", with: "")
            .replacingOccurrences(of: "-4bit", with: "")
    }
}
