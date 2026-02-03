//
//  ModelRow.swift
//  Hiyo
//
//  Individual model list item with status indicators.
//

import SwiftUI

struct ModelRow: View {
    let model: MLXModel
    let isLoaded: Bool
    let isLoading: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(isLoaded ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: iconName)
                    .font(.system(size: 14))
                    .foregroundStyle(isLoaded ? .accent : .secondary)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(model.name)
                    .font(.system(size: 13, weight: .medium))
                
                Text(model.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Label(model.size, systemImage: "externaldrive")
                    Label(model.parameters, systemImage: "cpu")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Status
            statusView
        }
        .padding(.vertical, 4)
        .background(isLoaded ? Color.accentColor.opacity(0.05) : Color.clear)
    }
    
    private var iconName: String {
        if model.name.contains("Code") {
            return "chevron.left.forwardslash.chevron.right"
        }
        if model.name.contains("Vision") {
            return "eye"
        }
        return "cpu"
    }
    
    @ViewBuilder
    private var statusView: some View {
        if isLoading {
            ProgressView()
                .scaleEffect(0.8)
                .frame(width: 24, height: 24)
        } else if isLoaded {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .imageScale(.large)
        } else {
            Image(systemName: "arrow.down.circle")
                .foregroundStyle(.secondary.opacity(0.5))
                .imageScale(.large)
        }
    }
}
