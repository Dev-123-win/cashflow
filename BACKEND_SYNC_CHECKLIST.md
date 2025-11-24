# ⚠️ BACKEND SYNC CHECKLIST

**CRITICAL:** Backend must be updated to match app changes!

---

## 🚨 REQUIRED BACKEND UPDATES

### File: `cloudflare-worker/src/index.ts`

#### 1. Update Constants (5 minutes)

```typescript
// OLD → NEW
const DAILY_CAP = 1.50;  →  const DAILY_CAP = 1.20;

const TASK_REWARDS = {
  survey: 0.10,        →  survey: 0.085,
  social_share: 0.10,  →  social_share: 0.085,
  app_rating: 0.10,    →  app_rating: 0.085,
};

const GAME_REWARDS = {
  tictactoe: 0.08,     →  tictactoe: 0.06,
  memory_match: 0.08,  →  memory_match: 0.06,
};

const AD_REWARD = 0.03;  →  const AD_REWARD = 0.025;
const SPIN_MAX = 1.00;   →  const SPIN_MAX = 0.75;

const MIN_WITHDRAWAL = 50.0;  →  const MIN_WITHDRAWAL = 100.0;
const WITHDRAWAL_FEE = 0.05;  →  const WITHDRAWAL_FEE = 0.02;
```

#### 2. Add Daily Cap Validation (30 minutes)

```typescript
async function validateDailyCap(userId, amount, firestore) {
  const today = new Date().toISOString().split('T')[0];
  const todayStart = new Date(today).getTime();
  
  const txns = await firestore
    .collection(`users/${userId}/transactions`)
    .where('timestamp', '>=', new Date(todayStart))
    .where('type', '==', 'earning')
    .where('status', '==', 'completed')
    .get();
  
  let todayEarnings = 0;
  txns.forEach(doc => todayEarnings += doc.data().amount || 0);
  
  if (todayEarnings + amount > 1.20) {
    throw new Error('Daily cap reached');
  }
}
```

#### 3. Update Transaction Structure (20 minutes)

```typescript
// OLD
await firestore.collection('transactions').add({...});

// NEW
await firestore
  .collection('users')
  .doc(userId)
  .collection('transactions')
  .add({
    userId,
    type: 'earning',
    source: 'task', // NEW FIELD
    amount: reward,
    status: 'completed',
    success: true,
    timestamp: FieldValue.serverTimestamp(),
  });
```

#### 4. Add Field Updates (15 minutes)

```typescript
// Add to all earning endpoints
await firestore.collection('users').doc(userId).update({
  availableBalance: FieldValue.increment(reward),
  totalEarned: FieldValue.increment(reward),
  dailyEarningsToday: FieldValue.increment(reward), // NEW
  lastActivity: FieldValue.serverTimestamp(),       // NEW
});
```

#### 5. Remove Leaderboard Updates (5 minutes)

```typescript
// DELETE THIS CODE from all earning endpoints
await firestore.collection('leaderboard').doc(userId).set({...});
```

---

## ✅ QUICK CHECKLIST

### Critical (Must Do)
- [ ] Update `DAILY_CAP` to 1.20
- [ ] Update `TASK_REWARDS` (0.085)
- [ ] Update `GAME_REWARDS` (0.06)
- [ ] Update `AD_REWARD` (0.025)
- [ ] Update `SPIN_MAX` (0.75)
- [ ] Update `MIN_WITHDRAWAL` (100.0)
- [ ] Update `WITHDRAWAL_FEE` (0.02)
- [ ] Add `validateDailyCap()` function
- [ ] Call `validateDailyCap()` in all earning endpoints
- [ ] Change transactions to subcollections
- [ ] Add `source` field to transactions
- [ ] Add `dailyEarningsToday` field updates
- [ ] Remove leaderboard updates

### High Priority
- [ ] Add request deduplication
- [ ] Update withdrawal fee calculation
- [ ] Add `lastActivity` timestamps

### Optional (Later)
- [ ] Add leaderboard caching
- [ ] Add user stats caching

---

## 🧪 TEST BEFORE DEPLOYING

```bash
# Test daily cap
curl -X POST http://localhost:8787/api/earn/task \
  -d '{"userId":"test","taskId":"survey"}'

# Should return: {"success":true,"reward":0.085}

# Test withdrawal minimum
curl -X POST http://localhost:8787/api/withdrawal/request \
  -d '{"userId":"test","amount":50}'

# Should return: {"error":"Minimum withdrawal is ₹100"}
```

---

## 🚀 DEPLOY

```bash
cd cloudflare-worker
wrangler deploy
```

---

## ⚠️ WARNING

**DO NOT deploy app to production without updating backend first!**

**Consequences:**
- ❌ Users could earn wrong amounts
- ❌ Daily cap mismatch
- ❌ Withdrawal validation fails
- ❌ Revenue model incorrect

---

**Estimated Time:** 1-2 hours  
**Priority:** CRITICAL  
**See:** `BACKEND_UPDATES_REQUIRED.md` for full details
