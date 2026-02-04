//
//  SetupStateView.swift
//  Hiyo
//
//  Shown when no MLX model is available — guides user through setup.
//

import SwiftUI

struct SetupStateView: View {
    @ObservedObject var provider: MLXProvider
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "cpu")
                .font(.system(size: 60))
                .foregroundStyle(.orange.opacity(0.8))
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: 8) {
                Text("Setup Required")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Hiyo needs an AI model to run locally on your Mac.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
            }
            
            // Setup steps
            VStack(alignment: .leading, spacing: 16) {
                SetupStep(
                    number: 1,
                    title: "Open Model Settings",
                    subtitle: "Choose from recommended models",
                    isActive: true
                )
                
                SetupStep(
                    number: 2,
                    title: "Download Your First Model",
                    subtitle: "1-4 GB download, cached locally",
                    isActive: false
                )
                
                SetupStep(
                    number: 3,
                    title: "Start Chatting",
                    subtitle: "Completely offline and private",
                    isActive: false
                )
            }
            .frame(width: 320)
            .padding(.vertical, 8)
            
            // Primary action
            Button(action: openSettings) {
                Label("Open Settings", systemImage: "gear")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 8)
            
            // Alternative: manual setup
            VStack(spacing: 8) {
                Text("Already have MLX models?")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Button("Scan for Existing Models") {
                    // Scan for local models
                }
                .buttonStyle(.link)
                .font(.caption)
            }
            .padding(.top, 16)
            
            // Learn more
            HStack(spacing: 4) {
                Text("Learn more about")
                Button("MLX Models") {
                    NSWorkspace.shared.open(AppURLs.mlxCommunity)
                }
                .buttonStyle(.link)
                .font(.callout)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.top, 16)
        }
        .padding()
    }
    
    private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}

struct SetupStep: View {
    let number: Int
    let title: String
    let subtitle: String
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Number badge
            ZStack {
                Circle()
                    .fill(isActive ? Color.accentColor : Color.secondary.opacity(0.2))
                    .frame(width: 28, height: 28)
                
                Text("\(number)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(isActive ? .white : .secondary)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout)
                    .fontWeight(isActive ? .semibold : .regular)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Status indicator
            if isActive {
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .opacity(isActive ? 1.0 : 0.6)
    }
}
