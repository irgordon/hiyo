sed -i 's/logger\.logPublic/SecurityLogger\.logPublic/g' Hiyo/Sources/Hiyo/Core/LLMModelFactory.swift
sed -i 's/logger\.log/SecurityLogger\.log/g' Hiyo/Sources/Hiyo/Core/LLMModelFactory.swift
sed -i 's/private let logger = SecurityLogger\.self//g' Hiyo/Sources/Hiyo/Core/LLMModelFactory.swift
