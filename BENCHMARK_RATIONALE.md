# Benchmark Rationale: Asynchronous Secure Deletion

## Context
The `SecureFileManager.secureDelete` function performs a secure deletion of files by overwriting them with random data three times before deleting the file. This process involves:
1.  Opening the file.
2.  Writing data equal to the file size (3 passes).
3.  Generating random data for each pass.
4.  Calling `sync()` (forcing a physical disk write) after each pass.
5.  Removing the item from the filesystem.

## Performance Issue
The `HiyoStore.clearAllData` method is annotated with `@MainActor`, meaning it executes on the main user interface thread. It calls `SecureMLX.clearAllCaches()`, which iteratively calls `SecureFileManager.secureDelete` for every file in the cache directory.

Executing blocking I/O operations, especially those involving `fsync` (via `sync()`), on the main thread causes the application UI to freeze (drop frames or become unresponsive) until the operation completes. If the cache contains large models (GBs in size), this freeze could last for seconds or minutes.

## Optimization Strategy
The optimization moves the blocking I/O operations in `secureDelete` to a background thread (using `Task.detached` or making the function `async`).

## Expected Improvement
*   **Metric:** Main Thread Block Time.
*   **Baseline:** The main thread is blocked for the entire duration of the secure delete operation (`Time(IO_Write * 3) + Time(fsync * 3) + Time(overhead)`).
*   **Optimized:** The main thread is blocked only for the time it takes to dispatch the asynchronous task (microseconds).

This change converts a synchronous, blocking operation into an asynchronous one, ensuring the UI remains responsive during data clearing operations.

# Benchmark Rationale: Sidebar Search Optimization

## Context
The `ConversationSidebar` view in SwiftUI previously used a computed property `filteredChats` that called `store.searchChats(query:)` directly. In SwiftUI, the `body` property is re-evaluated frequently (e.g., on hover, focus change, or parent state change). This caused the database query (even if O(1) via Predicate) to execute on every render frame on the main thread.

## Performance Issue
*   **Redundant I/O:** Every UI update triggered a database fetch.
*   **Main Thread Blocking:** While SwiftData is fast, repeated context fetches on the main thread compete for resources and can cause micro-stutters during animations or rapid typing.

## Optimization Strategy
We introduced `@State private var searchResults: [Chat]` to cache the results. The search is now only performed when:
1.  `searchText` changes.
2.  The underlying data (`store.chats`) changes.

This moves the query execution from the "Render Loop" to the "Event Loop".

## Expected Improvement
*   **Metric:** Database Fetch Frequency per Minute.
*   **Baseline:** Proportional to UI framerate/interaction rate (potentially 60+ calls/sec during animations).
*   **Optimized:** Proportional to user typing speed (e.g., 5-10 calls/sec max) or data updates (rare).
*   **Result:** Net reduction in main thread CPU usage and context lock contention.
