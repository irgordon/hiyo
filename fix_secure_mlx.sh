sed -i 's/MLX\.GPU\.totalMemory()/nil/g' Hiyo/Sources/Hiyo/Security/SecureMLX.swift
sed -i 's/\.configurationError/\.suspiciousEnvironment/g' Hiyo/Sources/Hiyo/Security/SecureMLX.swift
