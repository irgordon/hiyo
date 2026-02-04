//
//  LoadingStateView.swift
//  Hiyo
//
//  Shown while downloading and loading MLX models.
//

import SwiftUI

struct LoadingStateView: View {
    var provider: MLXProvider
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated loading indicator
            ZStack {
                Circle()
                    .stroke(Color.accentColor.opacity(0.2), lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: provider.loadingProgress)
                    // Fix: .accent is not a member of ShapeStyle, use Color.accentColor
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: provider.loadingProgress)
                
                Image(systemName: "arrow.down")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.accentColor)
            }
            
            VStack(spacing: 8) {
                Text("Loading Model...")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(provider.currentModel.displayName)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            // Progress bar
            VStack(spacing: 8) {
                ProgressView(value: provider.loadingProgress)
                    .frame(width: 240)
                
                HStack {
                    Text("\(Int(provider.loadingProgress * 100))%")
                        .font(.caption)
                        .monospacedDigit()
                    
                    Spacer()
                    
                    Text(estimatedTimeRemaining)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 240)
            }
            .padding(.top, 8)
            
            // Info text
            Text("Models download once and are cached locally. This may take a few minutes on first use.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
                .padding(.top, 16)
            
            Button("Cancel") {
                // Cancel loading
            }
            .buttonStyle(.bordered)
            .padding(.top, 16)
        }
        .padding()
    }
    
    private var estimatedTimeRemaining: String {
        if provider.loadingProgress < 0.1 {
            return "Calculating..."
        }
        // Rough estimate: assume linear progress
        let remaining = (1.0 - provider.loadingProgress) / max(provider.loadingProgress, 0.01)
        let seconds = Int(remaining * 10) // Assume 10 seconds per 10%
        
        if seconds < 60 {
            return "~\(seconds)s remaining"
        } else {
            return "~\(seconds / 60)m remaining"
        }
    }
}
