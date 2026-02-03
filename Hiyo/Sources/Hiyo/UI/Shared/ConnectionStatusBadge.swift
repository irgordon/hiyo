//
//  ConnectionStatusBadge.swift
//  Hiyo
//
//  MLX status indicator for toolbar.
//

import SwiftUI

struct ConnectionStatusBadge: View {
    @ObservedObject var provider: MLXProvider
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.system(size: 11, weight: .medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(backgroundStyle)
        .cornerRadius(6)
        .help(helpText)
    }
    
    private var statusColor: Color {
        if provider.isLoading {
            return .orange
        }
        if provider.isAvailable {
            return .green
        }
        return .red
    }
    
    private var statusText: String {
        if provider.isLoading {
            return "Loading \(Int(provider.loadingProgress * 100))%"
        }
        if provider.isAvailable {
            let model = provider.currentModel == "None" ? "Ready" : "Active"
            return model
        }
        return "Setup"
    }
    
    private var backgroundStyle: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(statusColor.opacity(0.3), lineWidth: 1)
            )
    }
    
    private var helpText: String {
        if provider.isLoading {
            return "Downloading and loading model into memory"
        }
        if provider.isAvailable {
            return "MLX is running on Apple Silicon GPU"
        }
        return "Click to open settings and download a model"
    }
}
