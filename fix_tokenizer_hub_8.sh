sed -i 's/PreTrainedTokenizer(/PreTrainedTokenizer(\n        tokenizerConfig: tokenizerConfig, tokenizerData: tokenizerData)/g' Hiyo/Sources/Hiyo/Core/LLM/Tokenizer.swift
