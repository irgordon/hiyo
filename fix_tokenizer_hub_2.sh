sed -i 's/LanguageModelConfigurationFromHub(modelFolder: directory, hubApi: hub)/LanguageModelConfigurationFromHub(modelFolder: directory)/g' Hiyo/Sources/Hiyo/Core/LLM/Tokenizer.swift
sed -i 's/hub: HubApi/hub: HubApi = HubApi()/g' Hiyo/Sources/Hiyo/Core/LLM/Tokenizer.swift
sed -i 's/LanguageModelConfigurationFromHub(modelName: configuration.tokenizerId ?? id, hubApi: hub)/LanguageModelConfigurationFromHub(modelName: configuration.tokenizerId ?? id)/g' Hiyo/Sources/Hiyo/Core/LLM/Tokenizer.swift
