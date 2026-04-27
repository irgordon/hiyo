sed -i 's/let maskToRemove = (cumsumProbs - sortedProbs) \.> topP/let maskToRemove = (cumsumProbs - sortedProbs) .> topP/g' Hiyo/Sources/Hiyo/Core/MLXProvider.swift
