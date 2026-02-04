# **Contributing to Hiyo**

Thank you for your interest in contributing to **Hiyo**, a privacy‑first, local‑only macOS AI application built with Swift, SwiftUI, and MLX.  
We welcome contributions of all kinds—code, documentation, testing, design, and security review.

This guide explains how to get started, how to structure contributions, and what standards to follow.

---

# **📌 Table of Contents**

1. [Project Philosophy](#project-philosophy)  
2. [Ways to Contribute](#ways-to-contribute)  
3. [Getting Started](#getting-started)  
4. [Development Workflow](#development-workflow)  
5. [Coding Standards](#coding-standards)  
6. [Security Expectations](#security-expectations)  
7. [Submitting Pull Requests](#submitting-pull-requests)  
8. [Contributor Recognition](#contributor-recognition)

---

# **🧭 Project Philosophy**

Hiyo is built around three core principles:

### **1. Local‑First**
All inference and processing must run on‑device.  
No cloud calls. No telemetry. No user data leaves the Mac.

### **2. macOS‑Native**
Hiyo should feel like a first‑class macOS app:
- SwiftUI  
- App Sandbox  
- Hardened Runtime  
- MLX GPU acceleration  
- Respect for system conventions  

### **3. Security by Design**
Every contribution must preserve:
- User privacy  
- Sandboxed behavior  
- Secure file handling  
- Safe model loading  
- Predictable resource usage  

---

# **🌱 Ways to Contribute**

### **Code**
- New features  
- Bug fixes  
- Performance improvements  
- Refactoring  

### **Documentation**
- Improving README, Quick Start, or build guides  
- Adding comments or clarifying complex logic  

### **Testing**
- Unit tests  
- UI tests  
- Reproducing and documenting bugs  

### **Design**
- UI/UX improvements  
- App icon or branding contributions  
- Accessibility enhancements  

### **Security**
- Reviewing entitlements  
- Hardening MLX model handling  
- Improving secure memory and file handling  

---

# **🛠 Getting Started**

### **Clone the repository**
```bash
git clone https://github.com/irgordon/hiyo.git
cd hiyo
```

### **Open in Xcode**
```bash
open Package.swift
```

### **Build & Run**
- **Cmd+B** — Build  
- **Cmd+R** — Run  

See `QUICK_START.md` for a fast setup guide.

---

# **🔄 Development Workflow**

1. **Create a feature branch**
   ```bash
   git checkout -b feature/my-improvement
   ```

2. **Make your changes**  
   Follow the coding and security standards below.

3. **Run tests**
   ```bash
   swift test
   ```

4. **Build in Release mode**
   ```bash
   swift build -c release
   ```

5. **Submit a Pull Request**  
   Include:
   - A clear description  
   - Screenshots if UI changes  
   - Notes on security impact  

---

# **📐 Coding Standards**

### **Swift Style**
- Follow Swift API Design Guidelines  
- Prefer clarity over cleverness  
- Avoid force‑unwraps (`!`)  
- Avoid `try?` unless failure is expected and handled  
- Use `@MainActor` for UI state  

### **SwiftUI**
- Keep views small and composable  
- Avoid heavy work in view builders  
- Use `@Observable` macros for state management

### **Concurrency**
- Prefer `async/await`  
- Avoid blocking the main thread  
- Use actors for shared mutable state  

### **File & Model Handling**
- Use `SecureMLX` for all model operations  
- Use `SecureFileManager` for deletion  
- Never bypass symlink checks  

---

# **🔐 Security Expectations**

Every contribution must pass the **Security‑Hardened Build Checklist**.

Key requirements:

- App Sandbox enabled  
- Hardened Runtime enabled  
- No sensitive data in logs  
- No network calls for inference  
- No unsafe entitlements  
- No unpinned dependencies  
- No experimental Swift flags unless justified  
- All model paths validated  
- All caches stored in sandboxed directories  

If your change touches:
- MLX  
- File I/O  
- Model loading  
- GPU memory  
- Secure memory  
- Export/import  

…please include a **Security Impact Note** in your PR.

---

# **📬 Submitting Pull Requests**

A good PR includes:

- A descriptive title  
- A clear explanation of the change  
- Before/after behavior  
- Screenshots for UI changes  
- Test coverage where applicable  
- Security impact notes (if relevant)  

PRs that modify security‑sensitive code may require additional review.

---

# **🏅 Contributor Recognition**

We value every contribution.  
Contributors are recognized in:

- GitHub commit history  
- Release notes  
- The project website (coming soon)  

Significant contributors may be invited to join the **Hiyo Core Team**.

---

# **💙 Thank You**

Your contributions help make Hiyo a secure and truly local macOS AI experience.  
