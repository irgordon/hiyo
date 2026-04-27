sed -i 's/LanguageModelConfigurationFromHub(\n                modelName: configuration.tokenizerId ?? id, hubApi: hub)/LanguageModelConfigurationFromHub(modelName: configuration.tokenizerId ?? id)/g' Hiyo/Sources/Hiyo/Core/LLM/Tokenizer.swift
sed -i 's/modelName: configuration.tokenizerId ?? id, hubApi: hub/modelName: configuration.tokenizerId ?? id/g' Hiyo/Sources/Hiyo/Core/LLM/Tokenizer.swift
