sed -i 's/@StateObject private var provider = MLXProvider()/@Environment(MLXProvider.self) private var provider/g' Hiyo/Sources/Hiyo/UI/Settings/ModelsSettings.swift
sed -i 's/@ObservedObject var provider: MLXProvider/var provider: MLXProvider/g' Hiyo/Sources/Hiyo/UI/Shared/ConnectionStatusBadge.swift
