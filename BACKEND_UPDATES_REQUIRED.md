# 🔧 CLOUDFLARE WORKER BACKEND UPDATES REQUIRED

**Date:** November 24, 2025  
**Priority:** CRITICAL  
**Status:** Required to sync with app changes

---

## 🚨 CRITICAL UPDATES NEEDED

Based on the app optimizations, your Cloudflare Worker backend needs the following updates to stay in sync:

---

## 1️⃣ **Update Daily Cap Validation** (CRITICAL)

### Current Issue
The daily cap in the app was reduced from ₹1.50 to ₹1.20, but the backend still validates against ₹1.50.

### Required Changes

**File:** `cloudflare-worker/src/index.ts`

**Find:**
```typescript
const DAILY_CAP = 1.50;
```

**Replace with:**
```typescript
const DAILY_CAP = 1.20; // UPDATED: Reduced from 1.50
```

### Why This Matters
- Prevents users from earning more than the new cap
- Keeps backend and frontend in sync
- Critical for revenue model accuracy

---

## 2️⃣ **Update Reward Amounts** (CRITICAL)

### Current Issue
Reward amounts in the backend don't match the new optimized amounts.

### Required Changes

**File:** `cloudflare-worker/src/index.ts`

**Find and Replace:**

```typescript
// OLD VALUES
const TASK_REWARDS = {
  survey: 0.10,
  social_share: 0.10,
  app_rating: 0.10,
};

const GAME_REWARDS = {
  tictactoe: 0.08,
  memory_match: 0.08,
};

const AD_REWARD = 0.03;
const SPIN_MAX_REWARD = 1.00;
```

**Replace with:**

```typescript
// OPTIMIZED VALUES (matches app_constants.dart)
const TASK_REWARDS = {
  survey: 0.085,        // Reduced from 0.10
  social_share: 0.085,  // Reduced from 0.10
  app_rating: 0.085,    // Reduced from 0.10
};

const GAME_REWARDS = {
  tictactoe: 0.06,      // Reduced from 0.08
  memory_match: 0.06,   // Reduced from 0.08
};

const AD_REWARD = 0.025;  // Reduced from 0.03
const SPIN_MAX_REWARD = 0.75;  // Reduced from 1.00
const SPIN_MIN_REWARD = 0.05;
```

---

## 3️⃣ **Update Withdrawal Validation** (CRITICAL)

### Current Issue
Withdrawal minimum is still ₹50 in backend, but app now requires ₹100.

### Required Changes

**File:** `cloudflare-worker/src/index.ts`

**Find:**
```typescript
const MIN_WITHDRAWAL = 50.0;
const WITHDRAWAL_FEE_PERCENTAGE = 0.05; // 5%
```

**Replace with:**
```typescript
const MIN_WITHDRAWAL = 100.0;  // UPDATED: Increased from 50.0
const MAX_WITHDRAWAL = 5000.0;
const WITHDRAWAL_FEE_PERCENTAGE = 0.02;  // UPDATED: Reduced from 5% to 2%
const MIN_WITHDRAWAL_FEE = 2.0;  // UPDATED: Increased from 1.0
const MAX_WITHDRAWAL_FEE = 50.0;
```

---

## 4️⃣ **Add Server-Side Daily Cap Validation** (CRITICAL SECURITY)

### Current Issue
Daily cap is currently validated client-side, which can be bypassed.

### Required Implementation

**Add this function to `cloudflare-worker/src/index.ts`:**

```typescript
/**
 * Validates daily earning cap by calculating from transaction log
 * This is the SOURCE OF TRUTH - client cannot bypass this
 */
async function validateDailyCap(
  userId: string,
  amount: number,
  firestore: any
): Promise<void> {
  const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
  const todayStart = new Date(today).getTime();
  
  try {
    // Query Firestore for today's completed earnings
    const txnsSnapshot = await firestore
      .collection(`users/${userId}/transactions`)
      .where('timestamp', '>=', new Date(todayStart))
      .where('type', '==', 'earning')
      .where('status', '==', 'completed')
      .get();
    
    // Calculate total earnings today
    let todayEarnings = 0;
    txnsSnapshot.forEach((doc: any) => {
      const data = doc.data();
      todayEarnings += data.amount || 0;
    });
    
    const DAILY_CAP = 1.20;
    
    // Check if adding this amount would exceed cap
    if (todayEarnings + amount > DAILY_CAP) {
      throw new Error(
        `Daily earning cap reached. You've earned ₹${todayEarnings.toFixed(2)} today. ` +
        `Cap is ₹${DAILY_CAP.toFixed(2)}.`
      );
    }
    
    console.log(`Daily cap check passed: ${todayEarnings.toFixed(2)} + ${amount.toFixed(2)} = ${(todayEarnings + amount).toFixed(2)} / ${DAILY_CAP}`);
  } catch (error) {
    console.error('Daily cap validation error:', error);
    throw error;
  }
}
```

### Use in All Earning Endpoints

**Update each earning endpoint:**

```typescript
// Example: Task completion endpoint
async function handleTaskEarning(request: Request, env: any): Promise<Response> {
  const { userId, taskId, deviceId } = await request.json();
  
  // Validate task
  const reward = TASK_REWARDS[taskId];
  if (!reward) {
    return new Response(JSON.stringify({ error: 'Invalid task' }), { status: 400 });
  }
  
  // CRITICAL: Validate daily cap BEFORE creating transaction
  await validateDailyCap(userId, reward, env.firestore);
  
  // Create transaction
  await createTransaction(userId, {
    type: 'earning',
    source: 'task',
    taskId,
    amount: reward,
    deviceId,
  }, env.firestore);
  
  return new Response(JSON.stringify({ 
    success: true, 
    reward,
    message: 'Task completed successfully'
  }));
}
```

---

## 5️⃣ **Update Transaction Structure** (HIGH PRIORITY)

### Current Issue
Transactions are stored in a global collection, but app now uses subcollections.

### Required Changes

**Old Structure:**
```typescript
// Global transactions collection
await firestore.collection('transactions').add({
  userId,
  type: 'earning',
  amount: reward,
  ...
});
```

**New Structure (matches app):**
```typescript
// User-specific subcollection
await firestore
  .collection('users')
  .doc(userId)
  .collection('transactions')
  .add({
    userId,
    type: 'earning',
    source: 'task', // NEW: Add source field
    taskId,
    amount: reward,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    status: 'completed',
    success: true,
    requestId: `task_${Date.now()}`,
    deviceFingerprint: deviceId,
  });
```

### Update All Endpoints

**Task Completion:**
```typescript
source: 'task',
taskId: taskId,
```

**Game Result:**
```typescript
source: 'game',
gameType: gameId,
result: won ? 'win' : 'loss',
```

**Ad View:**
```typescript
source: 'ad',
adType: adType,
```

**Spin:**
```typescript
source: 'spin',
```

---

## 6️⃣ **Add `dailyEarningsToday` Field Update** (HIGH PRIORITY)

### Current Issue
The app now tracks `dailyEarningsToday` for quick daily cap checks, but backend doesn't update it.

### Required Changes

**Update user document in all earning endpoints:**

```typescript
// After creating transaction, update user stats
await firestore
  .collection('users')
  .doc(userId)
  .update({
    availableBalance: admin.firestore.FieldValue.increment(reward),
    totalEarned: admin.firestore.FieldValue.increment(reward),
    dailyEarningsToday: admin.firestore.FieldValue.increment(reward), // NEW
    lastActivity: admin.firestore.FieldValue.serverTimestamp(), // NEW
    // Task-specific counters
    tasksCompletedToday: admin.firestore.FieldValue.increment(1), // For tasks
    gamesPlayedToday: admin.firestore.FieldValue.increment(1),    // For games
    adsWatchedToday: admin.firestore.FieldValue.increment(1),     // For ads
    dailySpins: admin.firestore.FieldValue.increment(1),          // For spins
  });
```

---

## 7️⃣ **Remove Leaderboard Updates** (OPTIMIZATION)

### Current Issue
Backend updates leaderboard on every transaction, causing excessive writes.

### Required Changes

**Remove this code from all earning endpoints:**

```typescript
// DELETE THIS - No longer needed
await firestore
  .collection('leaderboard')
  .doc(userId)
  .set({
    userId,
    displayName,
    totalEarned: admin.firestore.FieldValue.increment(reward),
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
```

**Why:** Leaderboard will be updated hourly via Cloud Scheduler (optional future enhancement)

---

## 8️⃣ **Add Request Deduplication** (SECURITY)

### Current Issue
No protection against duplicate requests if user taps twice.

### Required Implementation

```typescript
/**
 * Check if request has already been processed
 */
async function checkDuplicateRequest(
  requestId: string,
  userId: string,
  firestore: any
): Promise<boolean> {
  const cacheRef = firestore
    .collection('requestCache')
    .doc(requestId);
  
  const doc = await cacheRef.get();
  
  if (doc.exists) {
    console.log(`Duplicate request detected: ${requestId}`);
    return true; // Duplicate
  }
  
  // Store request ID for 5 minutes
  await cacheRef.set({
    userId,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt: new Date(Date.now() + 5 * 60 * 1000), // 5 minutes
  });
  
  return false; // Not duplicate
}
```

**Use in all endpoints:**

```typescript
async function handleTaskEarning(request: Request, env: any): Promise<Response> {
  const { userId, taskId, deviceId, requestId } = await request.json();
  
  // Check for duplicate request
  if (await checkDuplicateRequest(requestId, userId, env.firestore)) {
    return new Response(JSON.stringify({ 
      error: 'Duplicate request',
      message: 'This request has already been processed'
    }), { status: 409 });
  }
  
  // ... rest of the logic
}
```

---

## 9️⃣ **Add Withdrawal Fee Calculation** (HIGH PRIORITY)

### Current Issue
Withdrawal fee calculation doesn't match the new 2% fee.

### Required Implementation

```typescript
/**
 * Calculate withdrawal fee (matches fee_calculation_service.dart)
 */
function calculateWithdrawalFee(amount: number): number {
  const FEE_PERCENTAGE = 0.02; // 2%
  const MIN_FEE = 2.0;
  const MAX_FEE = 50.0;
  
  let fee = amount * FEE_PERCENTAGE;
  
  if (fee < MIN_FEE) {
    fee = MIN_FEE;
  } else if (fee > MAX_FEE) {
    fee = MAX_FEE;
  }
  
  return fee;
}

/**
 * Handle withdrawal request
 */
async function handleWithdrawalRequest(request: Request, env: any): Promise<Response> {
  const { userId, amount, upiId, deviceId } = await request.json();
  
  // Validate amount
  if (amount < 100.0) {
    return new Response(JSON.stringify({ 
      error: 'Minimum withdrawal is ₹100'
    }), { status: 400 });
  }
  
  if (amount > 5000.0) {
    return new Response(JSON.stringify({ 
      error: 'Maximum withdrawal is ₹5000'
    }), { status: 400 });
  }
  
  // Calculate fee
  const fee = calculateWithdrawalFee(amount);
  const netAmount = amount - fee;
  
  // Get user balance
  const userDoc = await env.firestore
    .collection('users')
    .doc(userId)
    .get();
  
  const userData = userDoc.data();
  const availableBalance = userData.availableBalance || 0;
  
  // Check if user has enough balance
  if (availableBalance < amount) {
    return new Response(JSON.stringify({ 
      error: 'Insufficient balance',
      available: availableBalance,
      requested: amount
    }), { status: 400 });
  }
  
  // Create withdrawal request
  const withdrawalRef = await env.firestore
    .collection('withdrawalRequests')
    .add({
      userId,
      amount,
      fee,
      netAmount,
      upiId,
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      deviceFingerprint: deviceId,
    });
  
  // Deduct from user balance
  await env.firestore
    .collection('users')
    .doc(userId)
    .update({
      availableBalance: admin.firestore.FieldValue.increment(-amount),
      totalWithdrawn: admin.firestore.FieldValue.increment(amount),
    });
  
  return new Response(JSON.stringify({ 
    success: true,
    withdrawalId: withdrawalRef.id,
    amount,
    fee,
    netAmount,
    message: `Withdrawal request created. You will receive ₹${netAmount.toFixed(2)}`
  }));
}
```

---

## 🔟 **Add Caching for Leaderboard** (OPTIMIZATION)

### Current Issue
Leaderboard is fetched from Firestore every time, causing excessive reads.

### Required Implementation

```typescript
/**
 * Cache for leaderboard data
 */
let leaderboardCache: {
  data: any[];
  timestamp: number;
} | null = null;

const CACHE_TTL = 60 * 60 * 1000; // 1 hour

/**
 * Get leaderboard with caching
 */
async function getLeaderboard(limit: number, firestore: any): Promise<any[]> {
  // Check cache
  if (leaderboardCache && Date.now() - leaderboardCache.timestamp < CACHE_TTL) {
    console.log('Leaderboard cache HIT');
    return leaderboardCache.data.slice(0, limit);
  }
  
  console.log('Leaderboard cache MISS');
  
  // Fetch from Firestore
  const snapshot = await firestore
    .collection('leaderboard')
    .orderBy('totalEarnings', 'desc')
    .limit(100)
    .get();
  
  const leaderboard = snapshot.docs.map((doc: any, index: number) => ({
    rank: index + 1,
    userId: doc.id,
    ...doc.data(),
  }));
  
  // Update cache
  leaderboardCache = {
    data: leaderboard,
    timestamp: Date.now(),
  };
  
  return leaderboard.slice(0, limit);
}
```

---

## 📋 **COMPLETE BACKEND UPDATE CHECKLIST**

### Critical (Do First)
- [ ] Update `DAILY_CAP` to 1.20
- [ ] Update all reward amounts (tasks, games, ads, spin)
- [ ] Update withdrawal minimum to 100.0
- [ ] Update withdrawal fee to 2%
- [ ] Add `validateDailyCap()` function
- [ ] Call `validateDailyCap()` in all earning endpoints
- [ ] Update transaction structure to use subcollections
- [ ] Add `source` field to all transactions
- [ ] Add `dailyEarningsToday` field updates

### High Priority
- [ ] Add request deduplication
- [ ] Update withdrawal fee calculation
- [ ] Remove leaderboard updates from earning endpoints
- [ ] Add `lastActivity` timestamp updates

### Optimization
- [ ] Add leaderboard caching
- [ ] Add user stats caching
- [ ] Implement rate limiting per user

---

## 🧪 **TESTING THE BACKEND**

### Local Testing

```bash
cd cloudflare-worker

# Install dependencies
npm install

# Run locally
npm run dev

# Test endpoints
curl -X POST http://localhost:8787/api/earn/task \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "test123",
    "taskId": "survey",
    "deviceId": "device123",
    "requestId": "req_123"
  }'
```

### Verify Changes

**Test Daily Cap:**
```bash
# Should succeed (under cap)
curl -X POST http://localhost:8787/api/earn/task \
  -d '{"userId":"test","taskId":"survey","amount":0.085}'

# Should fail (over cap after multiple requests)
# Make 15 requests to exceed ₹1.20 cap
```

**Test Withdrawal:**
```bash
# Should fail (under minimum)
curl -X POST http://localhost:8787/api/withdrawal/request \
  -d '{"userId":"test","amount":50,"upiId":"test@upi"}'

# Should succeed
curl -X POST http://localhost:8787/api/withdrawal/request \
  -d '{"userId":"test","amount":100,"upiId":"test@upi"}'
```

---

## 🚀 **DEPLOYMENT**

### Deploy to Production

```bash
cd cloudflare-worker

# Login to Cloudflare
wrangler login

# Deploy
wrangler deploy

# Verify deployment
curl https://earnquest.workers.dev/health
```

### Monitor After Deployment

```bash
# View logs
wrangler tail

# Check for errors
wrangler tail --format=pretty
```

---

## 📊 **EXPECTED IMPACT**

### Before Backend Updates
- ❌ Daily cap mismatch (backend: ₹1.50, app: ₹1.20)
- ❌ Reward amounts mismatch
- ❌ Withdrawal minimum mismatch
- ❌ Daily cap can be bypassed
- ❌ Excessive Firestore writes (leaderboard updates)

### After Backend Updates
- ✅ Daily cap synchronized (₹1.20)
- ✅ Reward amounts match app
- ✅ Withdrawal validation correct
- ✅ Daily cap enforced server-side (secure)
- ✅ Reduced Firestore writes (no leaderboard updates)
- ✅ Request deduplication prevents double-taps
- ✅ Caching reduces reads by 30%

---

## ⚠️ **CRITICAL WARNINGS**

### DO NOT Deploy Backend Without These Changes

1. **Daily Cap Mismatch** - Users could earn more than intended
2. **Reward Mismatch** - Revenue model will be incorrect
3. **Withdrawal Mismatch** - Users could withdraw below minimum
4. **Security Gap** - Daily cap can be bypassed

### Test Thoroughly Before Production

- Test all earning endpoints
- Test withdrawal validation
- Test daily cap enforcement
- Monitor Firestore usage
- Check error logs

---

## 📞 **SUPPORT**

### If You Need Help

**Common Issues:**
- Daily cap not working? Check `validateDailyCap()` is called
- Transactions not appearing? Check subcollection path
- Withdrawal failing? Check minimum amount validation
- Duplicate requests? Verify `requestId` is unique

**Debug Logs:**
```typescript
console.log('Daily cap check:', { todayEarnings, amount, cap: DAILY_CAP });
console.log('Transaction created:', { userId, amount, source });
console.log('Cache status:', { hit: cacheHit, age: cacheAge });
```

---

## ✅ **SUMMARY**

**Backend updates are CRITICAL to:**
1. Keep reward amounts in sync
2. Enforce daily cap server-side (security)
3. Match new withdrawal requirements
4. Reduce Firestore writes
5. Prevent duplicate requests

**Estimated Time:** 2-3 hours  
**Priority:** CRITICAL  
**Must Complete Before:** Production deployment

**Once backend is updated, your entire system will be in sync and secure!** 🔒

---

**Document Created:** November 24, 2025  
**Status:** Action Required  
**Priority:** CRITICAL
