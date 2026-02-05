# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Performance
- Offloaded `exportChats` operation (JSON encoding and AES encryption) to a detached background task, preventing main thread blocking when exporting large conversation histories.

## [v1.0.1] - 2024-05-24

### Architecture
- Introduced `NavigationCoordinator` to centralize app navigation logic (sidebar, inspector, chat selection) using `@Observable` and `@MainActor` isolation.
- Refactored `ContentView` and `HiyoApp` to utilize `NavigationCoordinator`, removing scattered state management.
- Enforced strict `@MainActor` isolation on `ChatView` and `ConversationInspector` to ensure UI correctness with SwiftData.
- Updated `ConversationSidebar` to use `ChatSummary` projection via SwiftData `@Query`, eliminating potential N+1 relationship faults in the list view.
- Ensured consistent dependency injection for `HiyoStore` and `MLXProvider` across the view hierarchy.

### Performance
- Eliminated potential main-thread bottlenecks by using lightweight `ChatSummary` structs for the sidebar list, preventing accidental full object instantiation.
- Improved sidebar search performance by leveraging SwiftData predicates directly on the summary projection.
- Offloaded synchronous model loading I/O (file reading, JSON decoding, weights loading) to a detached background task, preventing main thread blocking during model initialization.

## [v1.0.0] - 2024-05-23

### Refactor
- Removed all dependencies on the Combine framework in favor of Swift Concurrency and the Observation framework.
- Migrated global state management (`HiyoState`, `HiyoStore`, `MLXProvider`) to use the `@Observable` macro.
- Replaced `ObservableObject` and `@Published` with standard Swift properties and observation tracking.
- Updated `ConversationSidebar` to use structured concurrency (`.task`) for search debounce instead of Combine publishers.
- Refactored `ContentView` to use `@Environment` and `@State` instead of `@EnvironmentObject` and `@StateObject`.
- Replaced `NotificationCenter` publishers in views with asynchronous sequences iterated in `.task` modifiers.
- Ensure all model controllers (`HiyoStore`, `MLXProvider`, `HiyoState`) remain `@MainActor` isolated for thread safety.
- Updated `ConversationRow` to directly use the `Chat` model, simplifying data flow.

### Performance
- Optimized LLM generation complexity from O(N^2) to O(N) using KV-Caching, ensuring constant-time per-token latency.
- Offloaded generation logic from `@MainActor` to prevent UI blocking during inference.
- Fixed Nucleus Sampling (top-p) implementation to correctly handle high-probability tokens.
- Eliminated redundant database queries in conversation list by caching search results, preventing O(1) database fetch on every UI render frame.
- Offloaded `duplicateChat` operation to a detached background task to prevent main thread blocking when copying large conversations.
- Moved secure deletion operations to a background thread to prevent UI freezing during cache clearing.
- Eliminated repeated full database fetches in `HiyoStore` by manually updating the chat list.
- Optimized prompt formatting in `MLXProvider` by using efficient string joining.
- Removed unused string accumulation in generation loop, eliminating unnecessary memory allocation and copying.
- Replaced iterative deletion with batch delete in `clearAllData`, improving performance from O(n) to O(1) database operations.
- Offloaded `importChats` to a detached background task to prevent blocking the main thread during large file imports.
- Replaced N+1 in-memory search filter with SwiftData `#Predicate` in `ConversationSidebar`, optimizing search complexity from O(N*M) to O(1) database query.
- Removed N+1 database save calls during token generation, moving persistence to end-of-stream to significantly reduce I/O overhead.
- Solved N+1 query issue in conversation list by denormalizing `lastMessagePreview` and `messageCount` to the `Chat` model, reducing database fetches from O(N) to O(1) during list rendering.
- Optimized `Chat.totalTokens` complexity from O(N) to O(1) by denormalizing token count into a cached field, updated incrementally on message changes.
- Strictly enforced O(1) rendering in `ConversationRow` by removing the fallback to `chat.messages`, preventing accidental N+1 relationship fetches.
- Offloaded model loading in `MLXProvider` to a detached background task using `LoadModelOperation` actor, preventing main thread blocking during large model initialization.
- Introduced `ModelLoadState` enum for robust state management during model loading operations.

### Accessibility
- Added accessibility labels and traits to conversation list items.
