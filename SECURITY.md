# Hiyo Security Architecture

This document details the security architecture, threat model, and defensive measures implemented in Hiyo. Hiyo is designed with a **zero-trust, local-first** philosophy where user data never leaves the device.

---

## Security Philosophy

> **"What happens on your Mac, stays on your Mac."**

Hiyo operates on three core security principles:

1. **Zero Network** — No external connections, ever
2. **Zero Knowledge** — We cannot access your data, even if we wanted to
3. **Zero Compromise** — Defense-in-depth with multiple security layers

---

## Threat Model

### Assets Protected

| Asset | Sensitivity | Protection Mechanism |
|-------|-------------|---------------------|
| Chat conversations | High | AES-256 encryption, sandboxed storage |
| Encryption keys | Critical | Secure Enclave, biometric ACL |
| Model weights | Medium | Sandboxed cache, integrity checks |
| User preferences | Low | Standard UserDefaults, no cloud sync |

### Threat Actors

| Actor | Capability | Mitigation |
|-------|------------|------------|
| Network attackers | Remote exploitation | No network stack |
| Malware | Process injection | Hardened runtime, code signing |
| Physical theft | Device access | FileVault + encrypted database |
| User error | Accidental exposure | Sandboxing, input validation |
| Supply chain | Compromised dependencies | SPM checksums, minimal deps |

### Out of Scope

- **System compromise** — We assume macOS integrity
- **Hardware attacks** — Requires physical access + advanced tools
- **Side-channel attacks** — Mitigated by MLX/Apple Silicon design

---

## Security Layers

Hiyo implements **8 layers of security defense**:

```
┌─────────────────────────────────────────┐
│  Layer 8: User Education                │
│  Clear UI indicators, warnings           │
├─────────────────────────────────────────┤
│  Layer 7: Audit Logging                 │
│  Privacy-preserving security events      │
├─────────────────────────────────────────┤
│  Layer 6: Resource Guarding             │
│  DoS prevention, memory limits           │
├─────────────────────────────────────────┤
│  Layer 5: Data Encryption               │
│  AES-256-GCM, Secure Enclave keys        │
├─────────────────────────────────────────┤
│  Layer 4: Input Validation              │
│  Injection prevention, sanitization      │
├─────────────────────────────────────────┤
│  Layer 3: Memory Safety                 │
│  Secure memory, automatic cleanup        │
├─────────────────────────────────────────┤
│  Layer 2: Sandboxing                    │
│  App Sandbox, hardened runtime           │
├─────────────────────────────────────────┤
│  Layer 1: Code Integrity                │
│  Signing, anti-tampering, anti-debug     │
└─────────────────────────────────────────┘
```

---

## Detailed Security Controls

### Layer 1: Code Integrity

**Purpose**: Ensure Hiyo hasn't been modified or tampered with

**Implementation** (`CodeIntegrity.swift`):

```swift
// Runtime signature verification
static func verifyIntegrity() -> Bool

// Debugger detection
static func isDebuggerAttached() -> Bool

// Environment variable checks
static func hasSuspiciousLibraries() -> Bool
```

**Checks performed**:
- ✅ Code signature validation on launch
- ✅ Debugger attachment detection (release builds)
- ✅ DYLD environment variable sanitization
- ✅ Library injection prevention

**Response to violation**: Immediate termination with security log entry

---

### Layer 2: Sandboxing

**Purpose**: Restrict app capabilities to minimum required

**Entitlements** (`Hiyo.entitlements`):

| Entitlement | Status | Purpose |
|-------------|--------|---------|
| `com.apple.security.app-sandbox` | ✅ Enabled | Process isolation |
| `com.apple.security.files.user-selected.read-write` | ✅ Enabled | Export/Import only |
| `com.apple.security.network.client` | ❌ **Disabled** | No network access |
| `com.apple.security.network.server` | ✅ Enabled | Localhost only (future) |
| `com.apple.security.cs.allow-jit` | ❌ Disabled | No JIT compilation |
| `com.apple.security.cs.debugger` | ❌ Disabled | No debugging |

**Hardened Runtime**:
- Library validation enforced
- Unsigned memory execution blocked
- DYLD environment variables ignored

---

### Layer 3: Memory Safety

**Purpose**: Prevent sensitive data exposure in memory

**Implementation** (`SecureMemory.swift`):

```swift
final class SecureMemory<T> {
    // Automatic secure cleanup
    func destroy()  // Overwrites with zeros before deallocation
    deinit         // Guaranteed cleanup
}

struct SecureKey {
    // Symmetric key with automatic wiping
    func withSymmetricKey<R>(...)  // Scoped access only
}
```

**Protections**:
- Encryption keys never stored in plain `Data`
- Automatic memory wiping on deallocation
- Scoped access prevents key leakage
- `memset` to zero before free

---

### Layer 4: Input Validation

**Purpose**: Prevent injection attacks and malformed data

**Implementation** (`InputValidator.swift`):

| Validation | Method | Blocks |
|------------|--------|--------|
| Model ID | Regex whitelist | Path traversal, command injection |
| User input | Length + character filters | Buffer overflow, control chars |
| Output | Truncation + sanitization | DoS via excessive output |
| File paths | Prefix validation | Directory traversal |
| XSS patterns | Keyword blacklist | Script injection |

**Blocked patterns**:
- Null bytes (`\0`)
- Control characters (except `\n`, `\t`)
- HTML/JS keywords (`<script>`, `javascript:`, `eval(`)
- Shell metacharacters (`;`, `|`, `&`, `$`, `` ` ``)

---

### Layer 5: Data Encryption

**Purpose**: Protect data at rest

**Implementation**:

```swift
// Database encryption
private static func retrieveOrCreateEncryptionKey() -> SymmetricKey

// Export encryption
func exportChats(to url: URL) throws {
    let sealedBox = try AES.GCM.seal(data, using: encryptionKey)
}

// Keychain storage
static func save(data: Data, account: String) throws
```

**Cryptography details**:

| Aspect | Implementation |
|--------|---------------|
| Algorithm | AES-256-GCM |
| Key derivation | Secure Enclave random generation |
| Key storage | Keychain with biometric ACL |
| IV/nonce | Random 96-bit per encryption |
| Authentication | GCM tag verification |

**Key lifecycle**:
1. Generated on first launch via `SecRandomCopyBytes`
2. Stored in Secure Enclave via Keychain
3. Retrieved only when needed (scoped access)
4. Never logged, never transmitted
5. Rotatable via "Clear All Data"

---

### Layer 6: Resource Guarding

**Purpose**: Prevent denial-of-service via resource exhaustion

**Implementation** (`ResourceGuard.swift`):

| Limit | Value | Purpose |
|-------|-------|---------|
| Max input length | 10,000 chars | Prevent memory DoS |
| Max output length | 50,000 chars | Prevent generation spam |
| Max tokens | 8,192 per request | Context window limit |
| Requests/second | 10 | Burst protection |
| Requests/minute | 60 | Sustained rate limit |
| Memory usage | 80% of physical RAM | System stability |

**Actor-based implementation**:
```swift
actor ResourceGuard {
    func checkResourceLimits() throws
    func allocateTokens(_ count: Int) throws
    func enforceMemoryLimit() throws
}
```

---

### Layer 7: Audit Logging

**Purpose**: Security monitoring without privacy compromise

**Implementation** (`SecurityLogger.swift`):

**Logged events**:
- `INTEGRITY_CHECK_FAILED` — Tampering detected
- `SANDBOX_ESCAPE_ATTEMPT` — Policy violation
- `INVALID_INPUT` — Validation failure
- `MODEL_LOADED` — Model activation
- `DATA_CLEARED` — User-initiated wipe

**Privacy preservation**:
- ❌ Never log user content
- ❌ Never log conversation data
- ❌ Never log prompts or responses
- ✅ Only log event types and metadata
- ✅ Sanitize all strings before logging

**Log destination**: Local OSLog only (no remote transmission)

---

### Layer 8: User Education

**Purpose**: Help users make informed security decisions

**UI indicators**:
- Connection status badge (always "Local")
- Privacy settings with clear explanations
- Warnings before destructive operations
- Visual confirmation of encryption status

---

## MLX-Specific Security

### Model Loading Security

| Check | Implementation |
|-------|---------------|
| Model ID validation | Regex whitelist (`username/model-name`) |
| Path traversal prevention | `..` and null byte detection |
| Symlink verification | Path component validation |
| Size validation | 1MB - 20GB acceptable range |
| Format validation | `.safetensors`, `.bin`, `.mlx` only |

### GPU Memory Protection

```swift
// Safe defaults
MLX.GPU.set(cacheLimit: 1_073_741_824)      // 1 GB
MLX.GPU.set(memoryLimit: 4_294_967_296)     // 4 GB

// Automatic cleanup on memory pressure
func enforceMemoryLimit() throws
```

---

## Data Flow Security

### Conversation Storage

```
User Input
    ↓
Input Validation (Layer 4)
    ↓
AES-256 Encryption (Layer 5)
    ↓
SwiftData Persistence
    ↓
Encrypted SQLite Database
    ↓
FileVault-Protected Disk
```

### Model Caching

```
Hugging Face Download (one-time)
    ↓
Integrity Verification
    ↓
Sandboxed Cache Directory
    ↓
MLX GPU Memory (when loaded)
    ↓
Automatic Unload on Memory Pressure
```

---

## Incident Response

### Detected Security Events

| Event | Response | User Notification |
|-------|----------|-----------------|
| Integrity check failure | Immediate termination | Silent (prevent info leak) |
| Debugger detected | Immediate termination | Silent |
| Sandbox escape attempt | Block + log | Silent |
| Rate limit exceeded | Request rejection | "Please slow down" |
| Memory limit exceeded | Generation halt | "Close other apps" |

### User-Initiated Security Actions

| Action | Confirmation | Effect |
|--------|------------|--------|
| Clear conversation | None | Deletes messages, keeps settings |
| Delete chat | None | Removes chat + messages |
| Clear all data | **Required** | Wipes everything, resets keys |
| Export conversation | None | Creates encrypted `.hiyo` file |
| Unload model | None | Frees GPU memory |

---

## Comparison: Hiyo vs Cloud AI

| Aspect | Hiyo (Local) | Cloud AI |
|--------|-------------|----------|
| Data transmission | **None** | Full prompts/responses |
| Data storage | **Encrypted locally** | Server databases |
| Privacy policy | **Yours** | Vendor's |
| Subpoena risk | **None** | High |
| Network requirement | **None** | Required |
| Latency | **<100ms** | 50-500ms |
| Cost after purchase | **$0** | Per-token pricing |

---

## Security Checklist for Deployment

- [ ] Code signing certificate valid
- [ ] Hardened runtime enabled
- [ ] App Sandbox active
- [ ] No network entitlements (verify with `codesign -d --entitlements`)
- [ ] Encryption key generation tested
- [ ] Secure deletion verified
- [ ] Rate limiting functional
- [ ] Input validation tested with fuzzing
- [ ] Memory limits enforced
- [ ] Audit logs functional

---

## Reporting Security Issues

**Please do not open public issues for security vulnerabilities.**

Instead, email: `security@hiyoapp.dev`

Include:
- Description of vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

**Response timeline**:
- Acknowledgment: 24 hours
- Initial assessment: 72 hours
- Fix timeline: Based on severity

---

## Security Resources

- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
- [Apple Security Guide](https://support.apple.com/guide/security/welcome/web)
- [MLX Security Documentation](https://github.com/ml-explore/mlx-swift)
- [Swift Security Best Practices](https://swift.org/documentation/)

---

## Version History

| Version | Date | Security Changes |
|---------|------|----------------|
| 1.0.0 | 2026 | Initial release with 8-layer security |

---

**Last updated**: February 1, 2026
**Security contact**: security@hiyoapp.dev
```
