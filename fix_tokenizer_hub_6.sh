sed -i 's/return try PreTrainedTokenizer(/return try PreTrainedTokenizer(tokenizerConfig: tokenizerConfig, tokenizerData: tokenizerData)/g' Hiyo/Sources/Hiyo/Core/LLM/Tokenizer.swift
