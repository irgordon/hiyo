//
//  HiyoWelcomeView.swift
//  Hiyo
//
//  Main welcome container with state-based content switching.
//

import SwiftUI

struct HiyoWelcomeView: View {
    @ObservedObject var provider: MLXProvider
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            if provider.isLoading {
                LoadingStateView(provider: provider)
            } else if !provider.isAvailable {
                SetupStateView(provider: provider)
            } else {
                ReadyStateView(provider: provider)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}
