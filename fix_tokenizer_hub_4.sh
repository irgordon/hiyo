sed -i 's/LanguageModelConfigurationFromHub(\n                modelName: configuration.tokenizerId ?? id)/LanguageModelConfigurationFromHub(modelName: configuration.tokenizerId ?? id, hubApi: hub)/g' Hiyo/Sources/Hiyo/Core/LLM/Tokenizer.swift
sed -i 's/modelName: configuration.tokenizerId ?? id)/modelName: configuration.tokenizerId ?? id, hubApi: hub)/g' Hiyo/Sources/Hiyo/Core/LLM/Tokenizer.swift
