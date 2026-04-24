sed -i -e 's/SecCSFlags(rawValue: kSecCSDefaultFlags)/SecCSFlags(rawValue: 0)/' Hiyo/Sources/Hiyo/Security/CodeIntegrity.swift
sed -i -e '102,125d' Hiyo/Sources/Hiyo/Security/CodeIntegrity.swift
sed -i -e 's/MLX.GPU.totalMemory() ?? (8 \* 1024 \* 1024 \* 1024)/16 \* 1024 \* 1024 \* 1024/' Hiyo/Sources/Hiyo/Security/SecureMLX.swift
sed -i -e 's/MLX.GPU.totalMemory() ?? (16 \* 1024 \* 1024 \* 1024)/16 \* 1024 \* 1024 \* 1024/' Hiyo/Sources/Hiyo/Security/SecureMLX.swift
sed -i -e 's/.configurationError/.invalidFileAccess/' Hiyo/Sources/Hiyo/Security/SecureMLX.swift
sed -i -e 's/config.urlCredentialPersistence = .none//' Hiyo/Sources/Hiyo/Security/SecureNetworkSession.swift
sed -i -e 's/@StateObject private var provider = MLXProvider()/@State private var provider = MLXProvider()/' Hiyo/Sources/Hiyo/UI/Settings/ModelsSettings.swift
sed -i -e 's/Section("Hardware")/Section(header: Text("Hardware"))/' Hiyo/Sources/Hiyo/UI/Settings/PerformanceSettings.swift
sed -i -e 's/@ObservedObject var provider/var provider/' Hiyo/Sources/Hiyo/UI/Shared/ConnectionStatusBadge.swift
sed -i -e '/import SwiftUI/d' Hiyo/Sources/Hiyo/UI/Shared/ConnectionStatusBadge.swift
sed -i -e 's/\.accentColor/Color.accentColor/' Hiyo/Sources/Hiyo/UI/Sidebar/ConversationRow.swift
sed -i -e 's/as: Chat.self//g' Hiyo/Sources/Hiyo/UI/Sidebar/ConversationSidebar.swift
sed -i -e 's/if let chat = store.modelContext.model(for: summary.id, )/if let chat = store.modelContext.model(for: summary.id, as: Chat.self)/g' Hiyo/Sources/Hiyo/UI/Sidebar/ConversationSidebar.swift
sed -i -e '/extension String {/,/}/d' Hiyo/Sources/Hiyo/UI/Sidebar/ConversationSidebar.swift
sed -i -e 's/\.stroke(.accent,/\.stroke(Color.accentColor,/' Hiyo/Sources/Hiyo/UI/Welcome/LoadingStateView.swift
sed -i -e 's/LanguageModelConfigurationFromHub(modelFolder: directory, hubApi: hub)/LanguageModelConfigurationFromHub(modelFolder: directory)/' Hiyo/Sources/Hiyo/Core/LLM/Tokenizer.swift
sed -i -e 's/LanguageModelConfigurationFromHub(/LanguageModelConfigurationFromHub(modelName: /' Hiyo/Sources/Hiyo/Core/LLM/Tokenizer.swift
sed -i -e 's/LanguageModelConfigurationFromHub(modelName: modelName: /LanguageModelConfigurationFromHub(modelName: /' Hiyo/Sources/Hiyo/Core/LLM/Tokenizer.swift
sed -i -e 's/, hubApi: hub//' Hiyo/Sources/Hiyo/Core/LLM/Tokenizer.swift
sed -i -e 's/try await loaded.tokenizerConfig/loaded.tokenizerConfig/' Hiyo/Sources/Hiyo/Core/LLM/Tokenizer.swift
sed -i -e 's/let hub = HubApi(downloadBase: secureCache)/let hub = Hub.HubApi(downloadBase: secureCache)/' Hiyo/Sources/Hiyo/Core/LLMModelFactory.swift
sed -i -e 's/logger.logPublic/SecurityLogger.logPublic/' Hiyo/Sources/Hiyo/Core/LLMModelFactory.swift
sed -i -e 's/logger.log(/SecurityLogger.log(/' Hiyo/Sources/Hiyo/Core/LLMModelFactory.swift
sed -i -e 's/\[weak self\] _, model, tokenizer/\[weak self\] model, tokenizer/' Hiyo/Sources/Hiyo/Core/MLXProvider.swift
sed -i -e 's/MLXArray(topP)/Float(topP)/' Hiyo/Sources/Hiyo/Core/MLXProvider.swift
sed -i -e 's/Text("MLX \\(MLX.version)")/Text("MLX v0.1.0")/' Hiyo/Sources/Hiyo/UI/Settings/ModelsSettings.swift
sed -i -e 's/LabeledContent("MLX Version", value: MLX.version)/LabeledContent("MLX Version", value: "v0.1.0")/' Hiyo/Sources/Hiyo/UI/Settings/PerformanceSettings.swift
