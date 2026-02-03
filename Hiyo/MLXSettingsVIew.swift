import SwiftUI
import MLX

struct MLXSettingsView: View {
    @EnvironmentObject var appState: HiyoState
    @StateObject private var provider = MLXProvider()
    @State private var selectedTab: SettingsTab = .models
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ModelsSettings(provider: provider)
                .tabItem { Label("Models", systemImage: "cpu") }
                .tag(SettingsTab.models)
            
            PerformanceSettings()
                .tabItem { Label("Performance", systemImage: "gauge.with.dots.needle.67percent") }
                .tag(SettingsTab.performance)
            
            PrivacySettings()
                .tabItem { Label("Privacy", systemImage: "hand.raised") }
                .tag(SettingsTab.privacy)
        }
        .frame(width: 650, height: 500)
    }
    
    enum SettingsTab {
        case models, performance, privacy
    }
}

struct ModelsSettings: View {
    @ObservedObject var provider: MLXProvider
    
    var body: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    ForEach(provider.availableModels) { model in
                        ModelRow(
                            model: model,
                            isLoaded: provider.currentModel == model.id,
                            isLoading: provider.isLoading && provider.currentModel == model.id
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            Task {
                                try? await provider.loadModel(model.id)
                            }
                        }
                    }
                } header: {
                    Text("Available Models")
                } footer: {
                    Text("Models are downloaded from Hugging Face and cached locally. Quantized models use 4-bit precision for efficiency.")
                        .font(.caption)
                }
            }
            .listStyle(.bordered)
            
            if provider.isAvailable && provider.currentModel != "None" {
                HStack {
                    Button("Unload Model") {
                        provider.unloadModel()
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Text("MLX \(MLX.version)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
        .navigationTitle("Models")
    }
}

struct ModelRow: View {
    let model: MLXModel
    let isLoaded: Bool
    let isLoading: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.name)
                    .font(.body)
                Text(model.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    Label(model.size, systemImage: "externaldrive")
                    Label(model.parameters, systemImage: "cpu")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else if isLoaded {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .imageScale(.large)
            }
        }
        .padding(.vertical, 4)
        .background(isLoaded ? Color.accentColor.opacity(0.1) : Color.clear)
    }
}

struct PerformanceSettings: View {
    @AppStorage("gpuCacheLimit") private var gpuCacheLimit = 1024
    @AppStorage("temperature") private var temperature = 0.7
    @AppStorage("maxTokens") private var maxTokens = 1024
    
    var body: some View {
        Form {
            Section("GPU Memory") {
                VStack(alignment: .leading) {
                    Text("Cache Limit: \(gpuCacheLimit) MB")
                    Slider(value: .init(
                        get: { Double(gpuCacheLimit) },
                        set: { gpuCacheLimit = Int($0) }
                    ), in: 512...4096, step: 256)
                    Text("Higher values improve performance but use more RAM")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Button("Clear GPU Cache") {
                    MLX.GPU.clearCache()
                }
            }
            
            Section("Generation") {
                VStack(alignment: .leading) {
                    Text("Temperature: \(temperature, specifier: "%.1f")")
                    Slider(value: $temperature, in: 0...2, step: 0.1)
                }
                
                VStack(alignment: .leading) {
                    Text("Max Tokens: \(maxTokens)")
                    Slider(value: .init(
                        get: { Double(maxTokens) },
                        set: { maxTokens = Int($0) }
                    ), in: 256...4096, step: 256)
                }
            }
            
            Section("Hardware") {
                LabeledContent("Device", value: "Apple Silicon")
                LabeledContent("GPU", value: MLX.GPU.isAvailable ? "Available" : "Unavailable")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Performance")
    }
}
