sed -i 's/PreTrainedTokenizer(/PreTrainedTokenizer(tokenizerConfig: tokenizerConfig, tokenizerData: tokenizerData)/g' Hiyo/Sources/Hiyo/Core/LLM/Tokenizer.swift
sed -i '/tokenizerConfig: tokenizerConfig, tokenizerData: tokenizerData)/d' Hiyo/Sources/Hiyo/Core/LLM/Tokenizer.swift
