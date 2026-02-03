//
//  ModelsSettings.swift
//  Hiyo
//
//  Model management, download, and selection.
//

import SwiftUI

struct ModelsSettings: View {
    @StateObject private var provider = MLXProvider()
    @State private var showingAddModel = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Model list
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
                            loadModel(model.id)
                        }
                    }
                } header: {
                    HStack {
                        Text("Recommended Models")
                        Spacer()
                        if provider.isLoading {
                            ProgressView()
                                .scaleEffect(0.6)
                                .frame(width: 16, height: 16)
                        } else {
                            Button("Refresh") {
                                provider.refreshAvailableModels()
                            }
                            .buttonStyle(.link)
                            .font(.caption)
                        }
                    }
                } footer: {
                    Text("Models are downloaded from Hugging Face and cached locally. 4-bit quantized models use less memory with minimal quality loss.")
                        .font(.caption)
                }
                
                Section("Advanced") {
                    Button("Add Custom Model...") {
                        showingAddModel = true
                    }
                    
                    Button("Browse MLX Community...") {
                        NSWorkspace.shared.open(AppURLs.mlxCommunity)
                    }
                    
                    Button("Open Model Cache Folder") {
                        openCacheFolder()
                    }
                }
            }
            .listStyle(.bordered(alternatesRowBackgrounds: true))
            
            // Bottom toolbar
            HStack {
                if provider.currentModel != "None" {
                    Button("Unload Model") {
                        provider.unloadModel()
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(provider.currentModel == "None" ? "No model loaded" : "Active: \(provider.currentModel.displayName)")
                        .font(.caption)
                    
                    Text("MLX \(MLX.version)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingAddModel) {
            AddCustomModelSheet()
        }
        .navigationTitle("Models")
    }
    
    private func loadModel(_ modelId: String) {
        Task {
            try? await provider.loadModel(modelId)
        }
    }
    
    private func openCacheFolder() {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Hiyo/Models")
        
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        NSWorkspace.shared.open(cacheDir)
    }
}

struct AddCustomModelSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var modelId = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Custom Model")
                .font(.headline)
            
            TextField("Hugging Face model ID (e.g., mlx-community/Mistral-7B)", text: $modelId)
                .textFieldStyle(.roundedBorder)
                .frame(width: 360)
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            
            Text("Model must be MLX-compatible and hosted on Hugging Face.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(width: 340)
            
            HStack {
                Button("Cancel") { dismiss() }
                
                Button("Download") {
                    addModel()
                }
                .buttonStyle(.borderedProminent)
                .disabled(modelId.isEmpty || isLoading)
            }
        }
        .padding()
        .frame(width: 420, height: 200)
    }
    
    private func addModel() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try InputValidator.validateModelIdentifier(modelId)
                // Start download...
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
