//
//  PerformanceSettings.swift
//  Hiyo
//
//  MLX generation performance tuning.
//

import SwiftUI
import MLX

struct PerformanceSettings: View {
    @Bindable var state = HiyoState.shared
    
    var body: some View {
        Form {
            Section("Generation Parameters") {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Temperature")
                        Spacer()
                        Text(String(format: "%.2f", state.temperature))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $state.temperature, in: 0.0...2.0, step: 0.05)
                    Text("Higher values make output more random, lower values make it more focused and deterministic.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Top P")
                        Spacer()
                        Text(String(format: "%.2f", state.topP))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $state.topP, in: 0.0...1.0, step: 0.05)
                    Text("Controls diversity via nucleus sampling. 1.0 means consider all tokens.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Max Tokens")
                        Spacer()
                        Text("\(state.maxTokens)")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: Binding(
                        get: { Double(state.maxTokens) },
                        set: { state.maxTokens = Int($0) }
                    ), in: 256...8192, step: 256)
                    Text("Maximum number of tokens to generate per response.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button("Reset to Defaults") {
                    state.temperature = 0.7
                    state.topP = 0.9
                    state.maxTokens = 1024
                }
                .buttonStyle(.bordered)
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("System Memory")
                        Spacer()
                        Text("\(Int(state.memoryUsage)) GB")
                            .monospacedDigit()
                    }
                    
                    ProgressView(value: min(state.memoryUsage / 32.0, 1.0))
                        .progressViewStyle(.linear)
                        .tint(state.memoryUsage > 24.0 ? .red : .blue)
                    
                    Text("Estimated MLX footprint. This device shares RAM between CPU and GPU.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Resource Usage")
            }
            
            Section {
                LabeledContent("Device", value: hardwareInfo)
                LabeledContent("MLX Version", value: "Unknown")
                LabeledContent("GPU Available", value: MLX.GPU.isAvailable ? "Yes" : "No")
            } header: {
                Text("Hardware")
            }
        }
        .formStyle(.grouped)
    }
    
    private var hardwareInfo: String {
        let size = ProcessInfo.processInfo.physicalMemory
        let gb = size / (1024 * 1024 * 1024)
        return "Apple Silicon (\(gb)GB RAM)"
    }
}
