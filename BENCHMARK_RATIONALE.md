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

# Benchmark Rationale: KV-Cache and Generation Optimization

## Context
The previous implementation of `streamGenerate` in `MLXProvider` performed a full forward pass on the entire sequence of tokens for every new token generated.
- `inputIds` grew by 1 token each step.
- `model(inputMLX)` was called with the full `inputIds` array.

## Performance Issue
*   **Quadratic Complexity (O(N^2)):** In Transformer models, the attention mechanism scales with the square of the sequence length if computed naively for the whole sequence. Even if optimized, re-computing the Key and Value matrices for all previous tokens at every step is redundant.
*   **Redundant Computation:** For a sequence of length N, the model processed `1 + 2 + 3 + ... + N` tokens, totaling `N(N+1)/2` token passes.

## Optimization Strategy
We implemented the Key-Value (KV) Cache pattern:
1.  **Prefill:** We process the initial prompt once to generate the initial cache state.
2.  **Incremental Generation:** For each subsequent step, we pass only the *last generated token* and the *cached state* to the model.
3.  **State Update:** The model returns the new token logits and an updated cache (containing the new token's K/V data appended to the history).

## Expected Improvement
*   **Metric:** Time per Token (Latency).
*   **Baseline:** Linearly increasing latency per token as the sequence grows (O(N) cost per step -> O(N^2) total).
*   **Optimized:** Constant (or near-constant) latency per token (O(1) cost per step -> O(N) total).
*   **Result:** Significant speedup for long generations, reduced memory bandwidth usage, and lower CPU/GPU utilization per token.

## Additional Fixes
*   **Actor Isolation:** Generation logic was moved from `@MainActor` to a detached struct, ensuring heavy computation doesn't block the UI thread.
*   **Nucleus Sampling:** Fixed logic where the highest probability token could be masked if it alone exceeded `topP`.
*   **Input Truncation:** Explicitly limiting input size prevents potential memory exhaustion attacks.

# Benchmark Rationale: Chat Model Denormalization

## Context
The `Chat` model calculated `totalTokens` and `lastMessage` via computed properties.
- `totalTokens`: Iterated over all associated `Message` objects to sum their usage (`O(N)`).
- `lastMessage`: Sorted all messages by timestamp to find the last one (`O(N log N)`).

These properties were accessed frequently by the UI (e.g., `ConversationRow` in the sidebar), causing significant performance degradation for chats with long histories.

## Performance Issue
*   **O(N) / O(N log N) Access:** Accessing a single property triggered a full traversal or sort of the relationship graph.
*   **Main Thread Blocking:** These computations happened on the main thread during UI rendering.

## Optimization Strategy
We denormalized these fields onto the `Chat` model:
- `totalTokensCache`: Maintained incrementally.
- `lastMessagePreview`: Already existed, but we now rely on it exclusively for lists.
- `messageCountCache`: Used to avoid counting the array.

We introduced `applyMessageAdded` and `applyMessageRemoved` to update these fields incrementally (O(1)) at the point of mutation.

## Expected Improvement
*   **Metric:** Property Access Time.
*   **Baseline:** `O(N)` for `totalTokens`, `O(N log N)` for `lastMessage`. For 1000 messages, this could take milliseconds per frame.
*   **Optimized:** `O(1)` (instant field access).
*   **Result:** Smoother scrolling in the sidebar and reduced CPU usage.
