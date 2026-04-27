sed -i 's/LabeledContent("Device", value: hardwareInfo)/LabeledContent("Device", value: hardwareInfo as String)/g' Hiyo/Sources/Hiyo/UI/Settings/PerformanceSettings.swift
sed -i 's/LabeledContent("MLX Version", value: MLX.version)/LabeledContent("MLX Version", value: MLX.version as String)/g' Hiyo/Sources/Hiyo/UI/Settings/PerformanceSettings.swift
sed -i 's/LabeledContent("GPU Available", value: MLX.GPU.isAvailable ? "Yes" : "No")/LabeledContent("GPU Available", value: (MLX.GPU.isAvailable ? "Yes" : "No") as String)/g' Hiyo/Sources/Hiyo/UI/Settings/PerformanceSettings.swift
