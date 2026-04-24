sed -i -e '382,384c\
        let status = keyData.withUnsafeMutableBytes {\
            SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!)\
        }\
        guard status == errSecSuccess else {\
            throw SecurityError.encryptionFailed\
        }' Hiyo/Sources/Hiyo/Core/HiyoStore.swift
