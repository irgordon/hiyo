# Hiyo Internal API Documentation

Complete reference for Hiyo's internal APIs, protocols, and data structures.

---

## Table of Contents

- [Core Architecture](#core-architecture)
- [Security Layer](#security-layer)
- [MLX Integration](#mlx-integration)
- [Data Models](#data-models)
- [UI Components](#ui-components)
- [Utilities](#utilities)
- [Notifications](#notifications)
- [Constants](#constants)

---

## Core Architecture

### HiyoApp

**File**: `HiyoApp.swift`

Main app entry point. Initializes MLX and security systems.

```swift
@main
struct HiyoApp: App {
    init()  // Sets up MLX GPU limits and security checks
    var body: some Scene  // Defines window and settings
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification)
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool
    func applicationWillTerminate(_ notification: Notification)
}
```

**MLX Initialization**:
```swift
MLX.GPU.set(cacheLimit: 1024 * 1024 * 1024)      // 1GB
MLX.GPU.set(memoryLimit: 4 * 1024 * 1024 * 1024) // 4GB
```

---

### HiyoState

**File**: `HiyoState.swift`

Global observable state shared across views.

```swift
@MainActor
class HiyoState: ObservableObject {
    // Published properties
    @Published var selectedModel: String
    @Published var isSidebarVisible: Bool
    @Published var gpuUsage: Double
    @Published var memoryUsage: Double
    @Published var isGenerating: Bool
    
    // User preferences (backed by @AppStorage)
    var temperature: Double
    var maxTokens: Int
    
    // Methods
    func updateGPUMetrics(activeMemory: Double, peakMemory: Double)
    func resetToDefaults()
}
```

---

### HiyoStore

**File**: `Core/HiyoStore.swift`

Main data persistence layer with encryption.

```swift
@MainActor
final class HiyoStore: ObservableObject {
    // Properties
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    @Published var currentChat: Chat?
    @Published var chats: [Chat]
    
    // Initialization
    init() throws  // Sets up encrypted SwiftData container
    
    // Chat Management
    func createChat(title: String, model: String) -> Chat
    func deleteChat(_ chat: Chat)
    func duplicateChat(_ chat: Chat)
    
    // Message Management
    func addMessage(_ content: String, role: MessageRole, to chat: Chat) -> Message
    func clearMessages(in chat: Chat)
    
    // Import/Export
    func exportChats(to url: URL) throws
    func importChats(from url: URL) throws
    func clearAllData()
    
    // Queries
    func fetchChats()
}
```

**Usage Example**:
```swift
@StateObject private var store = try! HiyoStore()

// Create chat
let chat = store.createChat(title: "My Chat", model: "mlx-community/Llama-3.2-3B")

// Add message
let message = store.addMessage("Hello", role: .user, to: chat)

// Export
try store.exportChats(to: exportURL)
```

---

## Security Layer

### SecureKeychain

**File**: `Security/SecureKeychain.swift`

Encrypted key storage with biometric protection.

```swift
enum SecureKeychain {
    static func save(data: Data, account: String) throws
    static func load(account: String, prompt: String?) throws -> Data
    static func delete(account: String) throws
}

enum KeychainError: Error {
    case accessControlCreationFailed
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)
    case itemNotFound
    case invalidData
    case deletionNotVerified
}
```

**Usage**:
```swift
// Save key
let keyData = generateKey()
try SecureKeychain.save(data: keyData, account: "hiyo.encryption")

// Load key
let loadedKey = try SecureKeychain.load(account: "hiyo.encryption")

// Delete
try SecureKeychain.delete(account: "hiyo.encryption")
```

---

### CodeIntegrity

**File**: `Security/CodeIntegrity.swift`

Runtime tamper detection.

```swift
enum CodeIntegrity {
    static func verifyIntegrity() -> Bool
    static func isDebuggerAttached() -> Bool
    static func hasSuspiciousLibraries() -> Bool
    static func enforceIntegrity()  // Terminates if compromised
}
```

**Security Events**:
```swift
enum SecurityEvent: String {
    case integrityCheckFailed
    case integrityViolation
    case suspiciousEnvironment
    case sandboxEscapeAttempt
    case modelLoaded
    case modelUnloaded
}
```

---

### SecureMemory

**File**: `Security/SecureMemory.swift`

Safe memory handling with automatic cleanup.

```swift
final class SecureMemory<T> {
    init(_ value: T)
    func withValue<R>(_ closure: (inout T) throws -> R) rethrows -> R
    func read<R>(_ closure: (T) throws -> R) rethrows -> R
    func destroy()  // Overwrites memory before deallocation
}

struct SecureKey {
    init(data: Data)
    init(size: Int = 32)  // Generates random key
    func withSymmetricKey<R>(_ operation: (SymmetricKey) throws -> R) rethrows -> R
    func destroy()
}
```

---

### InputValidator

**File**: `Security/InputValidator.swift`

Input sanitization and validation.

```swift
enum InputValidator {
    static let maxInputLength = 10000
    static let maxOutputLength = 50000
    
    static func validateModelIdentifier(_ model: String) throws -> String
    static func validateInput(_ input: String) throws -> String
    static func sanitizeOutput(_ output: String) -> String
    static func validateFilePath(_ path: String, allowDirectory: Bool = false) throws -> URL
}

enum ValidationError: Error {
    case invalidModelIdentifier
    case suspiciousCharacters
    case emptyInput
    case tooLong(Int, Int)
    case nullByteDetected
    case controlCharacters
    case potentiallyMalicious
    case directoryTraversal
    case invalidPath
    case isDirectory
}
```

---

### ResourceGuard

**File**: `Security/ResourceGuard.swift`

Actor-based resource limiting.

```swift
actor ResourceGuard {
    static let shared: ResourceGuard
    
    func checkResourceLimits() throws
    func allocateTokens(_ count: Int) throws
    func releaseTokens(_ count: Int)
    func enforceMemoryLimit() throws
}

enum ResourceError: Error {
    case rateLimitExceeded(String)
    case contextWindowExceeded
    case invalidTokenCount
    case memoryLimitExceeded
}
```

**Usage**:
```swift
try await ResourceGuard.shared.checkResourceLimits()
try await ResourceGuard.shared.allocateTokens(tokenCount)
// ... use tokens ...
await ResourceGuard.shared.releaseTokens(tokenCount)
```

---

### SecurityLogger

**File**: `Security/SecurityLogger.swift`

Privacy-preserving security event logging.

```swift
enum SecurityLogger {
    static func log(_ event: SecurityEvent, details: String = "")
    static func logPublic(_ event: SecurityEvent, details: String)
}

enum SecurityEvent: String {
    // Integrity
    case integrityCheckFailed
    case integrityViolation
    case suspiciousEnvironment
    
    // Sandbox
    case sandboxEscapeAttempt
    case invalidFileAccess
    
    // Input
    case invalidInput
    case injectionAttempt
    
    // Network
    case networkBlocked
    
    // Model
    case modelLoaded
    case modelUnloaded
    case modelLoadFailed
    
    // Data
    case exportOperation
    case importOperation
    case dataCleared
}
```

---

## MLX Integration

### MLXProvider

**File**: `Core/MLXProvider.swift`

Main interface to MLX framework for model loading and inference.

```swift
@MainActor
final class MLXProvider: ObservableObject {
    // Published State
    @Published var isAvailable: Bool
    @Published var isLoading: Bool
    @Published var loadingProgress: Double
    @Published var currentModel: String
    @Published var memoryUsage: Double
    
    // Model Access
    var availableModels: [MLXModel]
    
    // Lifecycle
    init()
    
    // Model Management
    func loadModel(_ modelId: String) async throws
    func unloadModel()
    func refreshAvailableModels()
    
    // Generation
    func generate(
        messages: [Message],
        parameters: GenerationParameters = .default
    ) async throws -> AsyncStream<String>
}
```

**GenerationParameters**:
```swift
struct GenerationParameters {
    var temperature: Float = 0.7   // 0.0 - 2.0
    var topP: Float = 0.9          // 0.0 - 1.0
    var maxTokens: Int = 1024      // 256 - 4096
    
    static let `default` = GenerationParameters()
}
```

**Usage Example**:
```swift
let provider = MLXProvider()

// Load model
try await provider.loadModel("mlx-community/Llama-3.2-3B-Instruct-4bit")

// Generate
let messages = [
    Message(role: "user", content: "Hello!")
]

let stream = try await provider.generate(messages: messages)
for try await token in stream {
    print(token, terminator: "")
}
```

---

### MLXModelRegistry

**File**: `Core/MLXModelRegistry.swift`

Curated model definitions.

```swift
struct MLXModel: Identifiable, Codable {
    let id: String           // Hugging Face model ID
    let name: String         // Display name
    let description: String  // Short description
    let size: String         // Human-readable size (e.g., "1.9 GB")
    let parameters: String   // Parameter count (e.g., "3B")
    let tags: [String]       // Category tags
}

final class MLXModelRegistry {
    let defaultModels: [MLXModel]
    
    func getModel(_ id: String) -> MLXModel?
    func models(tagged tag: String) -> [MLXModel]
}
```

**Built-in Models**:
| ID | Name | Size | Parameters |
|----|------|------|------------|
| `mlx-community/Llama-3.2-1B-Instruct-4bit` | Llama 3.2 1B | 0.7 GB | 1B |
| `mlx-community/Llama-3.2-3B-Instruct-4bit` | Llama 3.2 3B | 1.9 GB | 3B |
| `mlx-community/Mistral-7B-Instruct-v0.3-4bit` | Mistral 7B | 4.1 GB | 7B |
| `mlx-community/Phi-3-mini-4k-instruct-4bit` | Phi-3 Mini | 1.8 GB | 3.8B |
| `mlx-community/Qwen2.5-7B-Instruct-4bit` | Qwen 2.5 7B | 4.2 GB | 7B |
| `mlx-community/CodeLlama-7B-Instruct-4bit` | CodeLlama 7B | 4.1 GB | 7B |

---

### SecureMLX

**File**: `Security/SecureMLX.swift`

MLX-specific security controls.

```swift
enum SecureMLX {
    static func validateModelID(_ id: String) throws -> String
    static func secureCacheDirectory() throws -> URL
    static func validateModelWeights(at url: URL) throws
    static func clearAllCaches() throws
    static func configureSafeLimits()
    static func verifyMLXConfiguration() -> Bool
}

enum MLXSecurityError: Error {
    case symbolicLinkInPath
    case weightsNotReadable
    case invalidWeights
    case invalidWeightsSize(UInt64)
    case invalidWeightsFormat(String)
}
```

---

## Data Models

### Chat

**File**: `Core/Models/Chat.swift`

Conversation container.

```swift
@Model
final class Chat {
    // Properties
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var modifiedAt: Date
    var modelIdentifier: String
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \Message.chat)
    var messages: [Message]
    
    // Initialization
    init(title: String, modelIdentifier: String)
    
    // Computed
    var messageCount: Int
    var lastMessage: Message?
    var totalTokens: Int
    var durationDescription: String
    
    // Methods
    func updateModifiedDate()
}
```

---

### Message

**File**: `Core/Models/Message.swift`

Individual chat message.

```swift
enum MessageRole: String, Codable {
    case system, user, assistant
}

@Model
final class Message {
    // Properties
    @Attribute(.unique) var id: UUID
    var content: String
    var role: MessageRole
    var timestamp: Date
    var tokensUsed: Int?
    var latencyMs: Double?
    
    // Relationships
    var chat: Chat?
    
    // Initialization
    init(content: String, role: MessageRole)
    
    // Computed
    var isFromUser: Bool
    var isFromAssistant: Bool
    var isSystem: Bool
    var displayContent: String
    var preview: String
    
    // Methods
    func formattedTimestamp(style: DateFormatter.Style = .short) -> String
}
```

---

### Message (Generation)

**File**: `Core/MLXProvider.swift`

Simplified message for MLX generation.

```swift
struct Message {
    let role: String      // "system", "user", "assistant"
    let content: String
}
```

---

## UI Components

### ContentView

**File**: `ContentView.swift`

Main three-column layout.

```swift
struct ContentView: View {
    @EnvironmentObject var appState: HiyoState
    @StateObject private var store: HiyoStore
    @StateObject private var provider: MLXProvider
    
    var body: some View  // NavigationSplitView with sidebar/chat/inspector
}
```

---

### ChatView

**File**: `UI/Chat/ChatView.swift`

Main conversation interface.

```swift
struct ChatView: View {
    let chat: Chat
    @ObservedObject var store: HiyoStore
    @ObservedObject var provider: MLXProvider
    
    @State private var inputText: String
    @State private var isGenerating: Bool
    @FocusState private var isInputFocused: Bool
    
    var body: some View
    func sendMessage()  // Handles generation
}
```

---

### HiyoWelcomeView

**File**: `UI/Welcome/HiyoWelcomeView.swift`

Welcome screen with state switching.

```swift
struct HiyoWelcomeView: View {
    @ObservedObject var provider: MLXProvider
    
    var body: some View  // Switches between Ready/Loading/Setup states
}

struct ReadyStateView: View {
    @ObservedObject var provider: MLXProvider
}

struct LoadingStateView: View {
    @ObservedObject var provider: MLXProvider
}

struct SetupStateView: View {
    @ObservedObject var provider: MLXProvider
}
```

---

### Settings Views

**File**: `UI/Settings/*.swift`

```swift
struct SettingsView: View {
    @State private var selectedTab: SettingsTab
}

struct ModelsSettings: View {
    @StateObject private var provider: MLXProvider
}

struct PerformanceSettings: View {
    @AppStorage var gpuCacheLimit: Double
    @AppStorage var temperature: Double
    @AppStorage var maxTokens: Int
}

struct PrivacySettings: View {
    @AppStorage var storeHistory: Bool
    @AppStorage var encryptExports: Bool
}

struct GeneralSettings: View {
    @AppStorage var startupAction: String
    @AppStorage var theme: String
    @AppStorage var fontSize: Int
}
```

---

## Utilities

### String Extensions

**File**: `Utils/Extensions/String+Validation.swift`

```swift
extension String {
    var trimmed: String
    var isBlank: Bool
    func truncated(to length: Int, addEllipsis: Bool = true) -> String
    var removingControlCharacters: String
    var normalizingLineEndings: String
    var estimatedTokenCount: Int
    var isSafeFilename: Bool
    var sanitizedFilename: String
    var isValidURL: Bool
    var codeBlocks: [(language: String?, code: String)]
    var strippingMarkdown: String
    var containsPotentialPII: Bool
    
    subscript(safe index: Int) -> Character?
    subscript(range: Range<Int>) -> String
}
```

---

### Date Extensions

**File**: `Utils/Extensions/Date+Formatting.swift`

```swift
extension Date {
    var conversationListFormatted: String
    var messageTimestampFormatted: String
    var detailedFormatted: String
    var iso8601Formatted: String
    var relativeDescription: String
    var timeAgo: String
    
    func isWithinLastDays(_ days: Int) -> Bool
    var startOfDay: Date
    var endOfDay: Date
    
    enum ConversationGroup: String, CaseIterable {
        case today, yesterday, thisWeek, thisMonth, older
    }
    var conversationGroup: ConversationGroup
}
```

---

### Constants

**File**: `Utils/Constants.swift`

```swift
enum AppInfo {
    static let name = "Hiyo"
    static let slogan = "Local Intelligence Powered by You."
    static let bundleIdentifier = "ai.hiyo.mac"
    static let version: String
    static let build: String
    static var fullVersion: String
}

enum UIConstants {
    static let minWindowWidth: CGFloat = 900
    static let minWindowHeight: CGFloat = 600
    // ... window sizes, sidebar widths, etc.
}

enum SecurityLimits {
    static let maxInputLength = 10000
    static let maxOutputLength = 50000
    static let maxRequestsPerSecond = 10
    static let maxRequestsPerMinute = 60
    static let maxContextTokens = 16384
    // ... etc.
}

enum MLXConfig {
    static let defaultModel = "mlx-community/Llama-3.2-3B-Instruct-4bit"
    static let recommendedModels: [String]
    static let defaultTemperature: Float = 0.7
    static let defaultTopP: Float = 0.9
    static let defaultMaxTokens = 1024
}

enum StorageKeys {
    static let selectedModel = "selectedModel"
    static let startupAction = "startupAction"
    static let theme = "theme"
    // ... etc.
}

enum ErrorMessages {
    static let genericError = "Something went wrong. Please try again."
    static let modelNotLoaded = "Please select and load a model in Settings."
    // ... etc.
}
```

---

## Notifications

**File**: `Core/SecureNotification.swift`

```swift
enum SecureNotification {
    static func post(name: Notification.Name, object: Any?, userInfo: [AnyHashable: Any]?)
    static func observe(name: Notification.Name, object: Any?, queue: OperationQueue, using: @escaping (Notification) -> Void) -> NSObjectProtocol
    static func remove(observer: NSObjectProtocol)
}

extension Notification.Name {
    // App lifecycle
    static let hiyoNewConversation
    static let hiyoClearConversation
    static let hiyoExportConversation
    static let hiyoFocusInput
    
    // Model events
    static let hiyoModelLoaded
    static let hiyoModelUnloaded
    static let hiyoModelLoadFailed
    
    // Generation events
    static let hiyoGenerationStarted
    static let hiyoGenerationCompleted
    static let hiyoGenerationCancelled
}
```

**Usage**:
```swift
// Post
SecureNotification.post(name: .hiyoNewConversation)

// Observe
let observer = SecureNotification.observe(name: .hiyoNewConversation) { notification in
    // Handle notification
}

// Remove
SecureNotification.remove(observer: observer)
```

---

## File Organization

```
Sources/Hiyo/
├── HiyoApp.swift              # App entry
├── ContentView.swift          # Main UI
├── HiyoState.swift            # Global state
├── Core/
│   ├── HiyoStore.swift        # Data persistence
│   ├── MLXProvider.swift      # MLX integration
│   ├── MLXModelRegistry.swift # Model definitions
│   ├── SecureNotification.swift
│   └── Models/
│       ├── Chat.swift
│       └── Message.swift
├── Security/
│   ├── SecureKeychain.swift
│   ├── CodeIntegrity.swift
│   ├── SecureMemory.swift
│   ├── SecureNetworkSession.swift
│   ├── SecureFileManager.swift
│   ├── ResourceGuard.swift
│   ├── SecurityLogger.swift
│   ├── InputValidator.swift
│   └── SecureMLX.swift
├── UI/
│   ├── Welcome/
│   │   ├── HiyoWelcomeView.swift
│   │   ├── ReadyStateView.swift
│   │   ├── LoadingStateView.swift
│   │   ├── SetupStateView.swift
│   │   └── FeatureRow.swift
│   ├── Chat/
│   │   ├── ChatView.swift
│   │   ├── MessageView.swift
│   │   ├── TypingIndicator.swift
│   │   └── LoadingProgressBar.swift
│   ├── Sidebar/
│   │   ├── ConversationSidebar.swift
│   │   └── ConversationRow.swift
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   ├── MLXSettingsView.swift
│   │   ├── ModelsSettings.swift
│   │   ├── ModelRow.swift
│   │   ├── PerformanceSettings.swift
│   │   ├── PrivacySettings.swift
│   │   └── GeneralSettings.swift
│   └── Shared/
│       ├── ModelPicker.swift
│       └── ConnectionStatusBadge.swift
└── Utils/
    ├── Extensions/
    │   ├── String+Validation.swift
    │   └── Date+Formatting.swift
    └── Constants.swift
```

---

## Version History

| Version | Date | API Changes |
|---------|------|-------------|
| 1.0.0 | 2026 | Initial API release |

---

**Last updated**: February 2026
**Documentation contact**: hello@hiyoapp.dev
