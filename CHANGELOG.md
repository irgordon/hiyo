# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

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

### Accessibility
- Added accessibility labels and traits to conversation list items.
