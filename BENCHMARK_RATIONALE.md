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

# Benchmark Rationale: Strict N+1 Prevention in ConversationRow

## Context
Despite the denormalization of `lastMessagePreview`, the `ConversationRow` view retained a fallback mechanism: `chat.lastMessagePreview ?? chat.messages.last?.content`. This fallback was intended to handle cases where the cache might be nil (e.g., legacy data or migration failures).

## Performance Issue
*   **Implicit N+1 Query:** Accessing `chat.messages` inside a SwiftUI view forces SwiftData to lazily fetch the entire relationship array from the database.
*   **Unpredictable Spikes:** If `lastMessagePreview` was ever nil, the main thread would block while fetching all messages for that chat, causing a dropped frame. In a list of 100 chats, a few nil caches could trigger multiple heavy database reads during a single scroll frame.

## Optimization Strategy
We removed the fallback entirely. The view now relies strictly on `lastMessagePreview`.
-   **Strict O(1) Enforcement:** The view layer is no longer permitted to access the relationship.
-   **Separation of Concerns:** Data consistency (ensuring the cache is populated) is enforced at the model/migration layer, not patched by the view.

## Expected Improvement
*   **Metric:** Scroll Performance (FPS) and Main Thread Block Time.
*   **Baseline:** Unpredictable performance; potential for random 100ms+ stutters if caches were missing.
*   **Optimized:** Guaranteed O(1) access for every row, ensuring consistent 60/120 FPS scrolling regardless of data state.

# Benchmark Rationale: Offload Model Loading

## Context
The `MLXProvider.loadModel` method was previously wrapping `LLMModelFactory.loadContainer` in a `Task { ... }`. By default, unstructured Tasks inherit the current actor context, which in this case was `@MainActor`.

## Performance Issue
*   **Main Thread Blocking:** Even though `LLMModelFactory` is async, any synchronous work done before suspension, or any continuation logic that wasn't strictly isolated, could contend with the Main Thread.
*   **UI Freeze:** Loading a large LLM (GBs of weights) involves significant I/O and memory mapping. If this happens on the Main Actor, the UI (animations, inputs) can stutter or freeze.

## Optimization Strategy
We refactored `loadModel` to use `Task.detached(priority: .userInitiated)`.
*   **Detached Task:** Breaks the actor inheritance, ensuring the closure runs on a background thread from the start.
*   **LoadModelOperation Actor:** Encapsulates the loading logic in a separate actor, guaranteeing isolation.
*   **MainActor Hopping:** We explicitly hop back to the Main Actor (`await MainActor.run`) only for essential state updates (`state`, `modelContainer`).

## Expected Improvement
*   **Metric:** UI responsiveness during model load.
*   **Baseline:** Potential frame drops during the initialization phase of the model loading.
*   **Optimized:** Zero main thread impact during heavy loading operations; UI remains fully interactive (showing progress bars smoothly).

# Benchmark Rationale: Offload Export Chats

## Context
The `HiyoStore.exportChats` method performs two heavy operations:
1.  **JSON Encoding:** Serializing the entire chat history (potentially thousands of messages) into JSON.
2.  **AES-GCM Encryption:** Encrypting the resulting JSON data.

Previously, this function was marked `throws` and called directly on the `@MainActor` (as `HiyoStore` is main-actor isolated).

## Performance Issue
*   **Main Thread Blocking:** For large databases (e.g., 50MB of chat history), encoding and encryption can take several seconds. Executing this on the main thread freezes the application completely.
*   **User Experience:** The user would see the "Beachball" cursor and the app would become unresponsive until the file write was complete.

## Optimization Strategy
We refactored the method to `async throws` and wrapped the heavy work in `Task.detached`.
1.  **Data Capture:** We map the SwiftData models (`Chat`, `Message`) to simple, Sendable DTO structs (`ChatDTO`, `MessageDTO`) on the Main Actor. This is fast and necessary because SwiftData models are not Sendable.
2.  **Offloading:** The DTOs are passed to a background thread where the computationally expensive `JSONEncoder` and `AES.GCM.seal` operations occur.

## Expected Improvement
*   **Metric:** Main Thread Block Duration.
*   **Baseline:** `Time(Encode) + Time(Encrypt) + Time(Disk Write)`. For large data, this could be >1.0s.
*   **Optimized:** `Time(Map to DTO)` (negligible, milliseconds).
*   **Result:** The UI remains responsive (no freezing) while the export happens in the background.
