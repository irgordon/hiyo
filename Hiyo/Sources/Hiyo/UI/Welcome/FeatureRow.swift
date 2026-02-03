//
//  FeatureRow.swift
//  Hiyo
//
//  Reusable feature highlight row for welcome screens.
//

import SwiftUI

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.accent)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.accent.opacity(0.1))
                )
            
            Text(text)
                .font(.callout)
                .foregroundStyle(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Variants

extension FeatureRow {
    /// Compact variant for smaller spaces
    static func compact(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.accent)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    /// Card variant with background
    static func card(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(.accent)
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.accent.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.callout)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.secondary.opacity(0.05))
        )
    }
}

// MARK: - Preview

#Preview("Default") {
    VStack(spacing: 12) {
        FeatureRow(icon: "bolt.fill", text: "Lightning fast inference")
        FeatureRow(icon: "lock.fill", text: "Secure and private")
        FeatureRow(icon: "cpu.fill", text: "Optimized for Apple Silicon")
    }
    .padding()
}

#Preview("Card Variant") {
    FeatureRow.card(
        icon: "sparkles",
        title: "MLX Powered",
        description: "Apple Silicon native machine learning for maximum performance"
    )
    .padding()
}
