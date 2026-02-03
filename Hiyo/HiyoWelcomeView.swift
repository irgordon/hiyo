struct HiyoWelcomeView: View {
    @ObservedObject var provider: MLXProvider
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            if provider.isLoading {
                LoadingStateView(provider: provider)
            } else if !provider.isAvailable {
                SetupStateView()
            } else {
                ReadyStateView(provider: provider)
            }
            
            Spacer()
        }
    }
}

struct ReadyStateView: View {
    @ObservedObject var provider: MLXProvider
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cpu.fill")
                .font(.system(size: 60))
                .foregroundStyle(.accent)
            
            Text("Welcome to Hiyo")
                .font(.system(size: 32, weight: .bold))
            
            Text("Apple Silicon Native AI")
                .font(.title3)
                .foregroundStyle(.secondary)
            
            Text("Hiyo uses MLX to run language models directly on your Mac's GPU, with no cloud connection needed.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
            
            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "bolt.fill", text: "Up to 2x faster than CPU inference")
                FeatureRow(icon: "memorychip", text: "Unified memory - no data copying")
                FeatureRow(icon: "lock.fill", text: "100% private, on-device only")
            }
            .frame(width: 320)
            .padding(.top, 24)
            
            if provider.currentModel == "None" {
                Button("Select a Model to Start") {
                    // Open settings
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 32)
            } else {
                Button("Start New Conversation") {
                    NotificationCenter.default.post(name: .newConversation, object: nil)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 32)
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.accent)
                .frame(width: 24)
            Text(text)
                .font(.callout)
            Spacer()
        }
    }
}

struct LoadingStateView: View {
    @ObservedObject var provider: MLXProvider
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading Model...")
                .font(.title2)
            
            Text(provider.currentModel)
                .font(.callout)
                .foregroundStyle(.secondary)
            
            ProgressView(value: provider.loadingProgress)
                .frame(width: 200)
        }
    }
}

struct SetupStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            
            Text("Setup Required")
                .font(.title2)
            
            Text("Hiyo needs to download an AI model to get started. Models are 1-4GB and will be cached locally.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
            
            Button("Open Model Settings") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
