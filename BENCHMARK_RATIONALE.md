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

# Benchmark Rationale: Duplicate Chat Optimization

## Optimization Description
The `duplicateChat` method in `HiyoStore` was identified as a performance bottleneck. The original implementation iterated through all messages in a chat, creating new `Message` objects and appending them to a new `Chat` object, all on the Main Actor. For chats with thousands of messages, this operation (combined with SwiftData's tracking overhead) caused noticeable UI freezes.

The optimization moves this entire operation to a `Task.detached` block, utilizing a background `ModelContext` to perform the fetch, duplication, and insertion. The main thread is only involved in initiating the task and updating the UI once the operation is complete.

## Theoretical Performance Improvement
- **Baseline (Blocking)**: $O(N)$ where $N$ is the number of messages. Blocking time includes:
  - Fetching messages (if faulting)
  - Allocating $N$ `Message` objects
  - Updating SwiftData relationships
  - `modelContext.save()` (disk I/O)
- **Optimized (Non-blocking)**: $O(1)$ blocking time on the Main Thread. The blocking time is reduced to:
  - Creating a `Task`
  - Fetching `modelContainer` reference
  - (Microseconds range)

The heavy lifting (I/O and allocation) happens in the background.

## Benchmark Verification
A benchmark file has been added at `Hiyo/Sources/Hiyo/Benchmarks/DuplicateChatBenchmark.swift`.

### Expected Results
Running `DuplicateChatBenchmark.run(messageCount: 1000)` should yield:
- **Baseline**: > 100ms (depending on device speed and disk I/O)
- **Optimized**: < 1ms (Main Thread blocking time)

This represents a near-infinite improvement in "UI responsiveness" during the operation.

## Correctness Considerations
- **Thread Safety**: Used `Task.detached` with a fresh `ModelContext` created from the `ModelContainer` to ensure SwiftData concurrency rules are respected.
- **Data Integrity**: Messages are explicitly sorted by `timestamp` during duplication to guarantee order preservation in the new chat, addressing a known SwiftData behavior where relationship order might be undefined after a fetch.
- **UI Updates**: The UI (`chats` array and `currentChat` selection) is updated on the Main Actor after the background task completes and the data is committed.
