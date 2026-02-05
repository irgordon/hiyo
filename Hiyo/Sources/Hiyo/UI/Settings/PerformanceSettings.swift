//
//  PerformanceSettings.swift
//  Hiyo
//
//  GPU memory, caching, and generation parameters.
//

import SwiftUI
import MLX

struct PerformanceSettings: View {
    @AppStorage(StorageKeys.gpuCacheLimit) private var gpuCacheLimit: Double = 1024
    @AppStorage(StorageKeys.temperature) private var temperature = 0.7
    @AppStorage(StorageKeys.maxTokens) private var maxTokens = 1024
    @AppStorage(StorageKeys.contextLength) private var contextLength = 4096
    
    @State private var showingCacheCleared = false
    
    var body: some View {
        Form {
            Section("GPU Memory") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Cache Limit")
                        Spacer()
                        Text("\(Int(gpuCacheLimit)) MB")
                            .monospacedDigit()
                    }
                    
                    Slider(value: $gpuCacheLimit, in: 512...4096, step: 256)
                    
                    Text("Higher values improve performance but use more RAM. Changes take effect after reloading the model.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Button("Clear GPU Cache Now") {
                    MLX.GPU.clearCache()
                    showingCacheCleared = true
                }
                .alert("Cache Cleared", isPresented: $showingCacheCleared) {
                    Button("OK") { }
                } message: {
                    Text("GPU memory cache has been cleared.")
                }
                
                LabeledContent("Active Memory", value: "\(MLX.GPU.activeMemory / 1024 / 1024) MB")
                LabeledContent("Peak Memory", value: "\(MLX.GPU.peakMemory / 1024 / 1024) MB")
            }
            
            Section("Generation Parameters") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Temperature")
                        Spacer()
                        Text(String(format: "%.1f", temperature))
                    }
                    
                    Slider(value: $temperature, in: 0...2, step: 0.1)
                    
                    Text("Lower values produce more focused output, higher values more creative.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Max Tokens")
                        Spacer()
                        Text("\(maxTokens)")
                            .monospacedDigit()
                    }
                    
                    Slider(value: .init(
                        get: { Double(maxTokens) },
                        set: { maxTokens = Int($0) }
                    ), in: 256...4096, step: 256)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Context Length")
                        Spacer()
                        Text("\(contextLength)")
                            .monospacedDigit()
                    }
                    
                    Slider(value: .init(
                        get: { Double(contextLength) },
                        set: { contextLength = Int($0) }
                    ), in: 2048...16384, step: 1024)
                    
                    Text("Maximum tokens to keep in conversation history.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section(header: Text("Hardware")) {
                LabeledContent("Device", value: hardwareInfo)
                LabeledContent("MLX Version", value: MLX.version)
                LabeledContent("GPU Available", value: MLX.GPU.isAvailable ? "Yes" : "No")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Performance")
    }
    
    private var hardwareInfo: String {
        let processInfo = ProcessInfo.processInfo
        #if arch(arm64)
        return "Apple Silicon (\(processInfo.processorCount) cores)"
        #else
        return "Intel (\(processInfo.processorCount) cores)"
        #endif
    }
}
