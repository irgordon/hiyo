//
//  ModelPicker.swift
//  Hiyo
//
//  Toolbar model selector with MLX model names.
//

import SwiftUI

struct ModelPicker: View {
    @Binding var selectedModel: String
    let models: [MLXModel]
    
    var body: some View {
        Picker("Model", selection: $selectedModel) {
            ForEach(models) { model in
                Text(model.displayName)
                    .tag(model.id)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .frame(minWidth: 180)
    }
}

extension MLXModel {
    var displayName: String {
        // Shorten common prefixes for cleaner UI
        name
            .replacingOccurrences(of: "mlx-community/", with: "")
            .replacingOccurrences(of: "-Instruct", with: "")
            .replacingOccurrences(of: "-4bit", with: "")
    }
}
