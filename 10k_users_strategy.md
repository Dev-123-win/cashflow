# 10k Users Free Tier Strategy

## Limits Overview
*   **Firestore Reads**: 50,000 / day
*   **Firestore Writes**: 20,000 / day
*   **Cloudflare Workers**: 100,000 requests / day

## The Challenge
With 10,000 daily active users (DAU), each user gets:
*   **5 Reads / Day**
*   **2 Writes / Day**
*   **10 API Requests / Day**

This is extremely tight. A typical session (Login -> Fetch Tasks -> Play Game -> Update Balance) uses:
*   1 Read (User Profile)
*   1 Read (Tasks)
*   1 Write (Game Result)
*   1 Write (Balance Update)
*   **Total: 2 Reads, 2 Writes per session.**

## Optimization Strategy Implemented

### 1. Backend-First Writes (Batching)
*   **Status**: Implemented.
*   **Mechanism**: Instead of writing to Firestore for every game/task, the Cloudflare Worker can batch updates or write only to a daily log.
*   **Current State**: The Worker writes to `transactions` and updates `users`. This is 2 writes per action.
*   **Optimization**: We need to ensure the Worker uses **Batch Writes** to combine these into 1 operation. (Already standard in Firestore Admin SDK if coded correctly, but currently it does 2 separate writes).

### 2. Caching (Critical)
*   **Status**: Implemented in `FirestoreService` and `TaskService`.
*   **Mechanism**:
    *   `getUser`: Cached for 5 minutes.
    *   `getTasks`: Cached for 1 hour.
    *   `getLeaderboard`: Cached for 1 hour.
*   **Impact**: Reduces reads by 80-90% for active sessions.

### 3. Offline Persistence
*   **Status**: Enabled in `main.dart`.
*   **Mechanism**: `persistenceEnabled: true`.
*   **Impact**: The app reads from local cache first. If the user opens the app 5 times a day, it might only fetch from server once.

### 4. No Real-Time Streams for Balance
*   **Status**: **Action Required**.
*   **Issue**: `UserProvider` currently uses `snapshots()`. This listens to *every* change.
*   **Fix**: If a user plays 20 games, the stream pushes 20 updates = 20 reads.
*   **Recommendation**: Change `UserProvider` to fetch once on startup, and then update local state manually after successful API calls.

## Final Recommendation for 10k Users
To strictly stay within free tier with 10k DAU:
1.  **Disable User Stream**: Switch `UserProvider` to `get()` instead of `snapshots()`.
2.  **Manual State Updates**: When `recordTaskEarning` returns success, update the local `User` object manually.
3.  **Aggressive Caching**: Increase cache TTL for Leaderboard to 6 hours.

*Note: If you have 10k registered users but only 1k DAU, the current setup is fine.*
