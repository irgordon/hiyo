# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Performance
- Optimized prompt formatting in `MLXProvider` by using efficient string joining.
- Removed unused string accumulation in generation loop, eliminating unnecessary memory allocation and copying.
- Replaced iterative deletion with batch delete in `clearAllData`, improving performance from O(n) to O(1) database operations.
- Offloaded `importChats` to a detached background task to prevent blocking the main thread during large file imports.
- Replaced N+1 in-memory search filter with SwiftData `#Predicate` in `ConversationSidebar`, optimizing search complexity from O(N*M) to O(1) database query.
