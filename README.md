<p align="center">
  <img src="logo.png" alt="Hiyo Logo" width="160" />
</p>

<h1 align="center">Hiyo</h1>
<p align="center"><strong>Local Intelligence Powered by You</strong></p>
<p align="center">
  <a href="#download"><img src="https://img.shields.io/badge/Download-macOS-007AFF?style=for-the-badge&logo=apple" alt="Download for macOS"></a>
  <a href="#build"><img src="https://img.shields.io/badge/Build-Swift-F05138?style=for-the-badge&logo=swift" alt="Build with Swift"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="MIT License"></a>
</p>

---

## Overview

**Hiyo** is your personal gateway to local AI — a sleek macOS app that brings powerful language models right to your desktop, no cloud required. Whether you're a tech enthusiast, hobbyist, or just curious about what AI can do, Hiyo makes it easy to explore complex ideas with clarity and control.

Its minimalist interface lets you prompt, experiment, and reason without distractions, while everything stays private and on-device. No logins, no data sharing — just fast, focused intelligence that works the way you do.

With Hiyo, you're not just using AI — you're shaping it.

---

## ✨ Core Features

| Feature | Description |
|---------|-------------|
| 🔒 **Privacy-First** | All conversations stay on your Mac. No cloud, no accounts, no tracking. |
| 🏠 **Local-Only** | Connects exclusively to localhost — your data never leaves your device. |
| 🤖 **Multi-Model Support** | Works with Ollama-compatible models: Llama 2, Mistral, CodeLlama, and more. |
| 🎨 **Native macOS Design** | Built with SwiftUI following Apple's Human Interface Guidelines. |
| 🔐 **Enterprise Security** | AES-256 encryption, sandboxed, hardened runtime, code signing verification. |
| ⚡ **Fast & Lightweight** | Optimized for Apple Silicon and Intel Macs. Minimal resource footprint. |
| 🛠️ **Developer Friendly** | Open source, hackable, with clean architecture for customization. |

---

## 🚀 Quick Start

### Prerequisites

- **macOS 14.0** (Sonoma) or later
- **Xcode 15** or later
- **Ollama** installed and running locally

### 1. Install Ollama

```bash
# Using Homebrew
brew install ollama

# Or download from https://ollama.ai
```

### 2. Start Ollama Service

```bash
ollama serve
```

### 3. Pull Your First Model

```bash
ollama pull llama2
```

---

## 🏗️ Build Instructions

### Clone the Repository

```bash
git clone https://github.com/hiyoai/hiyo.git
cd hiyo
```

### Open in Xcode

```bash
open Hiyo.xcodeproj
```

### Configure Signing

1. Select the **Hiyo** project in Xcode
2. Select the **Hiyo** target
3. Go to **Signing & Capabilities**
4. Set your **Team** (Personal or Developer Account)
5. Update **Bundle Identifier** if needed (default: `ai.hiyo.mac`)

### Build & Run

```bash
# Command line build
xcodebuild -project Hiyo.xcodeproj -scheme Hiyo -configuration Release build

# Or use Xcode: Product → Build (⌘B)
# Then: Product → Run (⌘R)
```

### Create Release Build

```bash
# Archive for distribution
xcodebuild -project Hiyo.xcodeproj -scheme Hiyo -configuration Release archive -archivePath Hiyo.xcarchive

# Export app
xcodebuild -exportArchive -archivePath Hiyo.xcarchive -exportOptionsPlist ExportOptions.plist -exportPath ./Release
```

---

## 📁 File Structure

```
Hiyo/
├── HiyoApp.swift                 # App entry point & lifecycle
├── ContentView.swift             # Main three-column layout
├── HiyoState.swift               # Global app state
│
├── Core/                         # Business Logic
│   ├── HiyoStore.swift           # SwiftData persistence layer
│   ├── HiyoProvider.swift        # Ollama API client
│   ├── SecureNotification.swift  # Internal notification system
│   └── Models/
│       ├── Chat.swift            # Conversation model
│       └── Message.swift         # Message model
│
├── Security/                     # Defense-in-depth security
│   ├── SecureKeychain.swift      # Encrypted key storage
│   ├── CodeIntegrity.swift       # Runtime tamper detection
│   ├── SecureMemory.swift        # Safe memory handling
│   ├── SecureNetworkSession.swift # Hardened networking
│   ├── SecureFileManager.swift   # Secure file operations
│   ├── ResourceGuard.swift       # DoS prevention
│   ├── SecurityLogger.swift      # Security event logging
│   └── InputValidator.swift      # Input sanitization
│
├── UI/                           # Interface Components
│   ├── Welcome/
│   │   ├── HiyoWelcomeView.swift # Branded welcome screen
│   │   ├── OfflineStateView.swift # Connection help
│   │   └── ModelCapsule.swift    # Model display component
│   │
│   ├── Chat/
│   │   ├── ChatView.swift        # Main conversation view
│   │   ├── MessageView.swift     # Message bubbles
│   │   └── TypingIndicator.swift # Loading animation
│   │
│   ├── Sidebar/
│   │   ├── ConversationSidebar.swift # Chat list
│   │   └── ConversationRow.swift     # List items
│   │
│   ├── Settings/
│   │   ├── SettingsView.swift    # Settings container
│   │   ├── GeneralSettings.swift # General preferences
│   │   ├── PrivacySettings.swift # Security controls
│   │   ├── ModelsSettings.swift  # Model management
│   │   └── AdvancedSettings.swift # Expert options
│   │
│   └── Shared/
│       ├── ModelPicker.swift     # Toolbar model selector
│       └── ConnectionStatusBadge.swift # Online indicator
│
├── Resources/
│   ├── Assets.xcassets/          # Icons & images
│   ├── Hiyo.entitlements         # Sandbox configuration
│   └── Info.plist                # App metadata
│
└── Tests/
    ├── HiyoTests.swift           # Unit tests
    └── HiyoUITests.swift         # UI automation
```

---

## 🔒 Security Architecture

Hiyo implements **8 layers of security** for production-grade protection:

```
┌─────────────────────────────────────────┐
│  1. Code Integrity Check                │
│     └─> Runtime signature verification  │
├─────────────────────────────────────────┤
│  2. App Sandbox                         │
│     └─> Strict entitlement enforcement  │
├─────────────────────────────────────────┤
│  3. Network Isolation                   │
│     └─> localhost-only connections      │
├─────────────────────────────────────────┤
│  4. Input Validation                    │
│     └─> Whitelist sanitization          │
├─────────────────────────────────────────┤
│  5. Memory Protection                   │
│     └─> Secure memory with auto-wipe    │
├─────────────────────────────────────────┤
│  6. Data Encryption                     │
│     └─> AES-256-GCM + Secure Enclave    │
├─────────────────────────────────────────┤
│  7. Resource Guarding                   │
│     └─> Rate limiting & DoS prevention  │
├─────────────────────────────────────────┤
│  8. Audit Logging                       │
│     └─> Privacy-preserving event log    │
└─────────────────────────────────────────┘
```

### Security Certifications

- ✅ **OWASP Mobile Top 10** compliant
- ✅ **CVE-2024-44148** mitigation (path traversal)
- ✅ **CVE-2025-31191** mitigation (keychain ACL)
- ✅ **Apple Hardened Runtime** enabled
- ✅ **App Sandbox** enforced

---

## 🛠️ Development

### Requirements

| Component | Version |
|-----------|---------|
| macOS | 14.0+ |
| Xcode | 15.0+ |
| Swift | 5.9+ |
| Ollama | 0.1.0+ |

### Architecture

Hiyo follows **Clean Architecture** principles:

- **Presentation Layer**: SwiftUI views with MVVM
- **Domain Layer**: Business logic in actors (thread-safe)
- **Data Layer**: SwiftData + secure file operations
- **Security Layer**: Cross-cutting security controls

### Key Technologies

- **SwiftData**: Type-safe persistence with CloudKit disabled
- **CryptoKit**: AES-256-GCM encryption
- **Network Framework**: Secure localhost networking
- **Security Framework**: Keychain with biometric ACL

---

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Quick Start for Contributors

```bash
# Fork and clone
git clone https://github.com/yourusername/hiyo.git

# Create branch
git checkout -b feature/amazing-feature

# Make changes and test
xcodebuild test -project Hiyo.xcodeproj -scheme Hiyo

# Commit and push
git commit -m "Add amazing feature"
git push origin feature/amazing-feature

# Open Pull Request
```

---

## 📜 License

Hiyo is released under the **MIT License**. See [LICENSE](LICENSE) for details.

```
MIT License

Copyright (c) 2024 Hiyo

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
```

---

## 🙏 Acknowledgments

- [Ollama](https://ollama.ai) — For making local LLMs accessible
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/) — For design excellence
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/) — For security standards
- [Swift Open Source Community](https://swift.org) — For the language and tools

---
