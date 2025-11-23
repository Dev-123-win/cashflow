# EarnQuest - Product Requirements Document

## Executive Summary

**Product Name:** EarnQuest  
**Platform:** Flutter (iOS, Android)  
**Version:** 1.0.0  
**Target Audience:** Indian users aged 18-35, mobile-first, looking for micro-earning opportunities  
**Core Value Proposition:** Earn real money through fun mini-games and simple tasks while watching ads

### Business Model
- **User Earning:** ₹1 per session average
- **App Revenue:** ₹4-5 per user session via AdMob
- **Profit Margin:** 4-5x multiplier on user payouts
- **Free Tier Sustainability:** 10,000 active users on Cloudflare + Firebase free tiers

---

## 1. Product Overview

### 1.1 Vision
Create a sustainable, engaging micro-earning platform that rewards users for their time while generating profitable ad revenue through strategic ad placement and earning caps.

### 1.2 Goals
- Launch MVP in 90 days
- Reach 10,000 users in first 6 months
- Maintain 4-5x revenue-to-payout ratio
- Keep 7-day retention above 35%
- Average 15+ ad impressions per daily active user

### 1.3 Success Metrics (KPIs)

| Metric | Target | Measurement |
|--------|--------|-------------|
| DAU/MAU Ratio | >25% | Daily/Monthly actives |
| Avg Revenue Per User (ARPU) | ₹12-15/month | AdMob earnings |
| Avg Payout Per User | ₹2.5-3/month | Withdrawal data |
| Revenue Multiplier | 4-5x | ARPU / Avg Payout |
| Ad Fill Rate | >90% | AdMob console |
| Withdrawal Completion Rate | >80% | Backend analytics |
| Fraud Rate | <2% | Anti-fraud system |
| Daily Session Length | 12-18 mins | Firebase Analytics |
| D1/D7/D30 Retention | 40%/25%/12% | Cohort analysis |

---

## 2. Technical Architecture

### 2.1 Tech Stack

**Frontend:**
- Flutter 3.16+
- Material 3 Design System
- Primary Font: Manrope (400, 500, 600, 700)
- State Management: Provider/Riverpod
- Local Storage: SharedPreferences + Hive

**Backend:**
- Cloudflare Workers (Serverless functions)
- Runtime: JavaScript/TypeScript
- Free Tier: 100,000 requests/day

**Database & Auth:**
- Firebase Auth (Email/Password, Google Sign-In)
- Firestore (Document database)
- Free Tier Limits:
  - 50,000 reads/day
  - 20,000 writes/day
  - 1GB storage

**Monetization:**
- Google AdMob
  - Rewarded Ads (primary)
  - Interstitial Ads
  - Native Ads
  - App Open Ads

**Analytics:**
- Firebase Analytics (free)
- Custom events for funnel tracking

### 2.2 System Architecture

```
┌─────────────┐
│   Flutter   │
│     App     │
└──────┬──────┘
       │
       ├─────────────┐
       │             │
┌──────▼──────┐ ┌───▼────────┐
│  Firebase   │ │ Cloudflare │
│   Auth +    │ │  Workers   │
│  Firestore  │ │  (API)     │
└─────────────┘ └────┬───────┘
                     │
              ┌──────▼──────┐
              │  AdMob SDK  │
              │ (Revenue)   │
              └─────────────┘
```

### 2.3 Firestore Schema

#### Users Collection (`users/{userId}`)
```json
{
  "userId": "string",
  "email": "string",
  "displayName": "string",
  "photoURL": "string?",
  "createdAt": "timestamp",
  "lastActive": "timestamp",
  
  "earnings": {
    "totalEarned": 0.0,
    "availableBalance": 0.0,
    "lifetimeWithdrawn": 0.0,
    "pendingWithdrawal": 0.0
  },
  
  "stats": {
    "totalAdsWatched": 0,
    "totalTasksCompleted": 0,
    "totalGamesPlayed": 0,
    "currentStreak": 0,
    "longestStreak": 0,
    "lastStreakDate": "timestamp"
  },
  
  "limits": {
    "lastResetDate": "timestamp",
    "todayTasksCompleted": 0,
    "todayAdsWatched": 0,
    "todayGamesPlayed": 0,
    "todayEarnings": 0.0
  },
  
  "referral": {
    "referralCode": "string (6-char unique)",
    "referredBy": "string?",
    "referralCount": 0,
    "referralEarnings": 0.0
  },
  
  "kyc": {
    "verified": false,
    "upiId": "string?",
    "fullName": "string?",
    "phone": "string?"
  },
  
  "security": {
    "deviceId": "string",
    "ipAddress": "string",
    "suspiciousActivity": false,
    "accountLocked": false
  }
}
```

#### Transactions Collection (`transactions/{transactionId}`)
```json
{
  "transactionId": "string (auto-generated)",
  "userId": "string",
  "type": "earn|withdrawal|referral|bonus",
  "amount": 0.0,
  "source": "task|game|ad|referral|spin",
  "status": "completed|pending|failed",
  "metadata": {
    "taskId": "string?",
    "gameType": "string?",
    "adUnitId": "string?"
  },
  "timestamp": "timestamp",
  "ipAddress": "string",
  "deviceId": "string"
}
```

#### Withdrawals Collection (`withdrawals/{withdrawalId}`)
```json
{
  "withdrawalId": "string",
  "userId": "string",
  "amount": 0.0,
  "upiId": "string",
  "status": "pending|processing|completed|failed|rejected",
  "requestedAt": "timestamp",
  "processedAt": "timestamp?",
  "failureReason": "string?",
  "transactionRef": "string?"
}
```

#### Leaderboard Collection (`leaderboard/{userId}`)
```json
{
  "userId": "string",
  "displayName": "string",
  "photoURL": "string?",
  "totalEarned": 0.0,
  "rank": 0,
  "lastUpdated": "timestamp"
}
```

#### Daily Spins Collection (`daily_spins/{userId}`)
```json
{
  "userId": "string",
  "lastSpinDate": "timestamp",
  "spinsUsedToday": 0,
  "totalSpins": 0
}
```

### 2.4 Cloudflare Workers API Endpoints

#### Base URL: `https://earnquest.workers.dev`

**1. POST /api/earn/task**
```typescript
// Request
{
  "userId": "string",
  "taskId": "string",
  "completionProof": "string",
  "deviceId": "string"
}

// Response
{
  "success": true,
  "earned": 0.50,
  "newBalance": 1.50,
  "message": "Task completed! ₹0.50 earned",
  "limits": {
    "todayTasksRemaining": 8,
    "todayEarningsRemaining": 4.50
  }
}
```

**2. POST /api/earn/game**
```typescript
// Request
{
  "userId": "string",
  "gameType": "tictactoe|memory",
  "score": 100,
  "duration": 45,
  "gameProof": "hash",
  "deviceId": "string"
}

// Response
{
  "success": true,
  "earned": 0.25,
  "newBalance": 1.75,
  "cooldownMinutes": 30
}
```

**3. POST /api/earn/ad**
```typescript
// Request
{
  "userId": "string",
  "adUnitId": "string",
  "adType": "rewarded|interstitial",
  "watched": true,
  "deviceId": "string"
}

// Response
{
  "success": true,
  "earned": 0.30,
  "newBalance": 2.05,
  "adsRemainingToday": 12
}
```

**4. POST /api/spin**
```typescript
// Request
{
  "userId": "string",
  "deviceId": "string"
}

// Response
{
  "success": true,
  "reward": 1.00,
  "rewardType": "cash|bonus|multiplier",
  "newBalance": 3.05,
  "nextSpinAvailableAt": "timestamp"
}
```

**5. GET /api/leaderboard**
```typescript
// Query params: ?limit=50

// Response
{
  "leaderboard": [
    {
      "rank": 1,
      "userId": "hidden",
      "displayName": "Rahul K.",
      "totalEarned": 245.50,
      "photoURL": "url"
    }
  ],
  "userRank": 127,
  "lastUpdated": "timestamp"
}
```

**6. POST /api/withdrawal/request**
```typescript
// Request
{
  "userId": "string",
  "amount": 10.0,
  "upiId": "user@paytm",
  "deviceId": "string"
}

// Response
{
  "success": true,
  "withdrawalId": "string",
  "estimatedProcessingTime": "24-48 hours",
  "status": "pending"
}
```

**7. GET /api/user/stats**
```typescript
// Query params: ?userId=xxx

// Response
{
  "earnings": {...},
  "stats": {...},
  "limits": {...},
  "canEarnToday": true,
  "nextResetTime": "timestamp"
}
```

### 2.5 Rate Limiting & Caching

**Cloudflare Worker Rate Limits:**
- Per IP: 100 requests/minute
- Per User: 50 requests/minute
- Leaderboard cache: 5 minutes
- User stats cache: 30 seconds

**Firestore Read Optimization:**
- Cache user data locally for 2 minutes
- Batch reads where possible
- Use Firestore offline persistence
- Leaderboard updates: Every 10 minutes (not real-time)

**Daily Quotas (to stay within free tier):**
- 10,000 users × 5 reads/day = 50,000 reads ✓
- Writes: Task completions + transactions ≈ 15,000/day ✓

---

## 3. Monetization Model

### 3.1 Revenue Formula

**Target: 4-5x multiplier**

```
User Earning per session = ₹1.00
App Revenue per session = ₹4.00 - ₹5.00
Profit per session = ₹3.00 - ₹4.00

Monthly per user:
- User earns: ₹2.50 - ₹3.00
- App earns: ₹12.00 - ₹15.00
- Profit: ₹9.00 - ₹12.00
```

### 3.2 Ad Revenue Model (India)

**AdMob eCPM Rates (India):**
- Rewarded Video: ₹80-150 per 1000 impressions (₹0.08-0.15 per ad)
- Interstitial: ₹40-80 per 1000 impressions (₹0.04-0.08 per ad)
- Native Ads: ₹20-50 per 1000 impressions (₹0.02-0.05 per ad)

**User Session Breakdown:**

| Activity | Ads Shown | User Earns | App Revenue |
|----------|-----------|------------|-------------|
| Open App | 1 App Open | ₹0 | ₹0.05 |
| Daily Task 1 | 1 Rewarded | ₹0.20 | ₹0.10 |
| Daily Task 2 | 1 Rewarded | ₹0.20 | ₹0.10 |
| Play Tic-Tac-Toe | 1 Interstitial | ₹0.15 | ₹0.06 |
| Play Memory Game | 1 Rewarded | ₹0.20 | ₹0.10 |
| Spin & Win | 1 Rewarded (unlock) | ₹0.10 | ₹0.10 |
| Watch 3 Bonus Ads | 3 Rewarded | ₹0.15 | ₹0.30 |
| Check Leaderboard | 1 Native | ₹0 | ₹0.03 |
| **Total** | **10 ads** | **₹1.00** | **₹0.84** |

**Problem:** Revenue is only 0.84x, not 4-5x!

### 3.3 Revised Earning Structure (4-5x Model)

**Strategy:** Reduce user payouts while maintaining engagement

| Activity | Ads Shown | User Earns | App Revenue | Notes |
|----------|-----------|------------|-------------|-------|
| Open App | 1 App Open | ₹0 | ₹0.05 | Daily |
| Daily Task 1 | 1 Rewarded | ₹0.10 | ₹0.10 | Survey/Quiz |
| Daily Task 2 | 1 Rewarded | ₹0.10 | ₹0.10 | Simple action |
| Daily Task 3 | 1 Rewarded | ₹0.10 | ₹0.10 | Social share |
| Tic-Tac-Toe Win | 1 Interstitial + 1 Rewarded | ₹0.08 | ₹0.16 | Cooldown: 30 min |
| Memory Game Win | 1 Rewarded | ₹0.08 | ₹0.10 | Cooldown: 30 min |
| Spin & Win (after ad) | 1 Rewarded | ₹0.05-0.50 | ₹0.10 | Random reward, 1x/day |
| Watch Bonus Ad 1 | 1 Rewarded | ₹0.03 | ₹0.10 | Optional |
| Watch Bonus Ad 2 | 1 Rewarded | ₹0.03 | ₹0.10 | Optional |
| Watch Bonus Ad 3 | 1 Rewarded | ₹0.03 | ₹0.10 | Optional |
| Watch Bonus Ad 4 | 1 Rewarded | ₹0.03 | ₹0.10 | Optional |
| Watch Bonus Ad 5 | 1 Rewarded | ₹0.03 | ₹0.10 | Optional |
| Mid-session Interstitial | 2 Interstitials | ₹0 | ₹0.12 | Between activities |
| **Daily Total** | **15 ads** | **₹0.63-1.03** | **₹1.43** | **2.3x ratio** |

**Monthly Model (25 active days/month):**
- User earns: ₹15.75 - ₹25.75
- App earns: ₹35.75 (25 days × ₹1.43)
- **Actual Ratio: ~1.4-2.3x**

### 3.4 Achieving 4-5x Multiplier

**Problem:** Indian eCPMs are too low for 4-5x with ethical earning rates.

**Solutions:**

1. **Reduce Withdrawal Threshold:**
   - Min withdrawal: ₹50 (not ₹10)
   - Forces 2-3 months of engagement
   - Many users churn before withdrawal

2. **Actual Payout Rate:**
   - Only 20-30% of users reach withdrawal threshold
   - Effective payout: ₹5-7.50/month (vs ₹25 earned)
   - App revenue stays: ₹35.75/month
   - **Effective Ratio: 4.8-7x** ✓

3. **Referral System (Zero Cost to App):**
   - Referrer earns ₹2 from referee's "earned" balance
   - Referee must earn ₹10 first
   - No actual payout increase for app

4. **Streak Bonuses (Time Inflation):**
   - Day 7 streak: ₹0.50 bonus (from accumulated ad revenue)
   - Day 14 streak: ₹1.00 bonus
   - Keeps users engaged longer

### 3.5 Ad Placement Strategy

**Session Flow:**

1. **App Open:** App Open Ad (100% frequency)
2. **Home Screen:** Native Ad in task list
3. **Before Task:** Rewarded Ad (required to unlock task)
4. **After Task:** Option to watch bonus ad
5. **Before Game:** Interstitial Ad (50% frequency)
6. **After Game Win:** Rewarded Ad to claim earnings
7. **Spin Unlock:** Rewarded Ad required
8. **Withdrawal Screen:** Native Ad
9. **Leaderboard:** Native Ad at bottom

**Daily Cap:** Max 15 rewarded + 3 interstitial = 18 ads/user/day

---

## 4. Daily Limits & Anti-Fraud

### 4.1 Daily Earning Caps

```javascript
const DAILY_LIMITS = {
  maxEarnings: 1.50,           // ₹1.50/day max
  maxTasks: 3,                  // 3 tasks/day
  maxGames: 6,                  // 6 games/day (2 per type)
  maxBonusAds: 5,               // 5 bonus ads/day
  maxSpins: 1,                  // 1 spin/day
  
  gameCooldown: 30,             // 30 min between same game
  spinCooldown: 24,             // 24 hours between spins
  
  weeklyEarningsCap: 10.00,     // ₹10/week max
  monthlyEarningsCap: 40.00     // ₹40/month max
};
```

### 4.2 Anti-Fraud Rules

**Device Fingerprinting:**
```dart
String getDeviceId() {
  return '${deviceInfo.id}_${deviceInfo.model}_${androidId}';
}
```

**Fraud Detection:**

1. **Multiple Accounts:**
   - Max 2 accounts per device
   - Max 3 accounts per IP (24h window)
   - Flag if >5 accounts from same WiFi

2. **Suspicious Patterns:**
   - Task completion < 5 seconds → Flag
   - Game completion time too fast → Invalidate
   - Sequential ad watches < 15 seconds apart → Block
   - >3 withdrawals failed → Lock account

3. **Velocity Checks:**
   - Max 1 task/minute
   - Max 1 game/5 minutes
   - Max 3 bonus ads/15 minutes

4. **Withdrawal Fraud:**
   - Min account age: 7 days
   - Min activity: 20 tasks completed
   - KYC required for >₹100 lifetime withdrawal
   - Manual review for first withdrawal >₹50

**Implementation (Worker):**
```typescript
async function validateEarning(request) {
  const { userId, deviceId, ipAddress } = request;
  
  // Check daily limits
  const limits = await getLimits(userId);
  if (limits.todayEarnings >= DAILY_LIMITS.maxEarnings) {
    return { error: 'Daily limit reached' };
  }
  
  // Check device
  const deviceCount = await getAccountsByDevice(deviceId);
  if (deviceCount > 2) {
    return { error: 'Device limit exceeded' };
  }
  
  // Check velocity
  const recentActivity = await getRecentActivity(userId);
  if (recentActivity.count > 10 && recentActivity.timeSpan < 300) {
    return { error: 'Too fast, slow down' };
  }
  
  return { valid: true };
}
```

---

## 5. User Interface & Experience

### 5.1 Design System

**Material 3 Expressive Theme:**

```dart
// Color Palette
const primaryColor = Color(0xFF6C63FF);      // Vibrant purple
const secondaryColor = Color(0xFF00D9C0);    // Teal
const tertiaryColor = Color(0xFFFFB800);     // Gold
const errorColor = Color(0xFFFF5252);
const successColor = Color(0xFF00E676);

const backgroundColor = Color(0xFF0F0F14);    // Dark bg
const surfaceColor = Color(0xFF1C1C23);       // Card bg
const surfaceVariant = Color(0xFF2A2A35);     // Elevated card

// Typography (Manrope)
final headlineL = TextStyle(
  fontFamily: 'Manrope',
  fontSize: 32,
  fontWeight: FontWeight.w700,
  height: 1.2,
);

final headlineM = TextStyle(
  fontFamily: 'Manrope',
  fontSize: 24,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

final bodyL = TextStyle(
  fontFamily: 'Manrope',
  fontSize: 16,
  fontWeight: FontWeight.w500,
  height: 1.5,
);

final labelL = TextStyle(
  fontFamily: 'Manrope',
  fontSize: 14,
  fontWeight: FontWeight.w600,
  letterSpacing: 0.5,
);

// Spacing
const space4 = 4.0;
const space8 = 8.0;
const space12 = 12.0;
const space16 = 16.0;
const space24 = 24.0;
const space32 = 32.0;

// Border Radius
const radiusS = 8.0;
const radiusM = 12.0;
const radiusL = 16.0;
const radiusXL = 24.0;
```

**Elevation & Shadows:**
```dart
final cardShadow = [
  BoxShadow(
    color: Colors.black.withOpacity(0.3),
    blurRadius: 20,
    offset: Offset(0, 8),
  ),
];

final glassMorphism = BoxDecoration(
  color: Colors.white.withOpacity(0.05),
  borderRadius: BorderRadius.circular(radiusL),
  border: Border.all(
    color: Colors.white.withOpacity(0.1),
    width: 1,
  ),
);
```

### 5.2 Component Library

**Earning Card:**
```dart
Widget EarningCard({
  required String title,
  required String amount,
  required String description,
  required VoidCallback onTap,
  IconData? icon,
  bool locked = false,
}) {
  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [primaryColor, secondaryColor],
      ),
      borderRadius: BorderRadius.circular(radiusL),
      boxShadow: cardShadow,
    ),
    child: Row(
      children: [
        if (icon != null)
          Icon(icon, color: Colors.white, size: 32),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: headlineM),
              Text(description, style: bodyL),
            ],
          ),
        ),
        Text(amount, style: headlineL.copyWith(color: tertiaryColor)),
      ],
    ),
  );
}
```

**Progress Bar:**
```dart
Widget EarningProgress({
  required double current,
  required double max,
}) {
  return Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Today\'s Earnings', style: labelL),
          Text('₹${current.toStringAsFixed(2)} / ₹${max.toStringAsFixed(2)}'),
        ],
      ),
      SizedBox(height: 8),
      LinearProgressIndicator(
        value: current / max,
        backgroundColor: surfaceVariant,
        valueColor: AlwaysStoppedAnimation(successColor),
      ),
    ],
  );
}
```

### 5.3 Screen Specifications

---

## 6. Detailed Screen-by-Screen Requirements

### 6.1 Splash Screen

**Duration:** 2 seconds

**UI Elements:**
- App logo (centered)
- App name "EarnQuest"
- Tagline: "Earn While You Play"
- Loading animation (circular progress)

**Technical:**
- Check for app updates
- Initialize Firebase
- Check auth state
- Preload AdMob

**Navigation:**
- If first launch → Onboarding
- If logged out → Login
- If logged in → Home

---

### 6.2 Onboarding (3 Slides)

**Slide 1: Welcome**
- Illustration: Person with coins raining
- Headline: "Earn Real Money"
- Body: "Complete simple tasks and play fun games to earn cash rewards"

**Slide 2: Play Games**
- Illustration: Game controller with money
- Headline: "Fun Mini Games"
- Body: "Play Tic-Tac-Toe, Memory Match, and more to earn daily"

**Slide 3: Get Paid**
- Illustration: Phone with UPI logo
- Headline: "Withdraw Anytime"
- Body: "Cash out directly to your UPI account. Minimum withdrawal ₹50"

**Actions:**
- Skip button (top-right)
- Next button
- Get Started button (Slide 3)

---

### 6.3 Authentication Screen

**Email/Password Login:**

```
┌─────────────────────────────────┐
│                                 │
│   [Logo]                        │
│                                 │
│   Welcome Back!                 │
│   Login to start earning        │
│                                 │
│   [Email Field]                 │
│   [Password Field]              │
│                                 │
│   [Forgot Password?]            │
│                                 │
│   [Login Button]                │
│                                 │
│   ─────── OR ───────            │
│                                 │
│   [Continue with Google]        │
│                                 │
│   Don't have an account?        │
│   [Sign Up]                     │
│                                 │
└─────────────────────────────────┘
```

**Sign Up Flow:**
- Email validation
- Password requirements (min 8 chars, 1 uppercase, 1 number)
- Auto-generate referral code on signup
- Check for referral code (optional field)

**Error States:**
- Invalid email
- Wrong password
- Account already exists
- Network error

---

### 6.4 Home Screen (Primary Screen)

**Layout:**

```
┌─────────────────────────────────┐
│ [Profile Pic]  EarnQuest  [🔔] │ // App Bar
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────┐   │
│  │  💰 Available Balance   │   │
│  │      ₹2.50              │   │ // Balance Card
│  │  [Withdraw Button]      │   │
│  └─────────────────────────┘   │
│                                 │
│  🔥 3 Day Streak                │ // Streak Badge
│                                 │
│  ─── Today's Progress ───       │
│  [Progress Bar: ₹0.40/₹1.50]   │
│                                 │
│  ─── Earn More ───              │
│                                 │
│  ┌───────────┐ ┌───────────┐   │
│  │  📋 Tasks │ │ 🎮 Games  │   │ // Category Cards
│  │  3 left   │ │  6 left   │   │
│  │  +₹0.30   │ │  +₹0.48   │   │
│  └───────────┘ └───────────┘   │
│                                 │
│  ┌───────────┐ ┌───────────┐   │
│  │ 🎰 Spin   │ │ 📺 Watch  │   │
│  │  Ready!   │ │  5 ads    │   │
│  │  +₹0.50   │ │  +₹0.15   │   │
│  └───────────┘ └───────────┘   │
│                                 │
│  [Native Ad]                    │
│                                 │
│  ─── Quick Links ───            │
│  🏆 Leaderboard                 │
│  👥 Invite Friends              │
│  📊 My Stats                    │
│                                 │
└─────────────────────────────────┘
│ [Home] [Tasks] [Games] [Profile]│ // Bottom Nav
└─────────────────────────────────┘
```

**Components:**

1. **Balance Card:**
   - Large, prominent display
   - Glassmorphism effect
   - Pulsing animation on earn
   - Disabled withdraw button if < ₹50

2. **Streak Badge:**
   - Fire emoji with count
   - Tooltip: "Come back daily to maintain streak"
   - Animates on streak milestone

3. **Progress Bar:**
   - Shows daily earnings vs cap
   - Color changes: Green (0-50%), Yellow (50-80%), Red (80-100%)

4. **Category Cards:**
   - 2×2 grid
   - Show remaining opportunities
   - Potential earnings
   - Subtle glow on tap

**Interactions:**
- Pull-to-refresh
- Smooth scroll
- Haptic feedback on taps
- Confetti animation on daily goal complete

**States:**
- Loading (shimmer effect)
- Daily limit reached (gray out cards)
- No internet (cached data + banner)

---

### 6.5 Tasks Screen

**Task Types:**

1. **Daily Survey (₹0.10)**
   - 3-5 multiple choice questions
   - Takes 30-60 seconds
   - Rewarded ad before unlock

2. **Social Share (₹0.10)**
   - Share app on WhatsApp/Instagram story
   - Verification via screenshot upload
   - Rewarded ad after completion

3. **App Rating (₹0.10)**
   - Rate app on Play Store
   - One-time task
   - Rewarded ad after completion

**UI Layout:**

```
┌─────────────────────────────────┐
│ ← Tasks                    [i] │
├─────────────────────────────────┤
│                                 │
│  📊 Daily Progress              │
│  [Progress: 1/3 tasks]          │
│                                 │
│  ─── Available Tasks ───        │
│                                 │
│  ┌─────────────────────────┐   │
│  │ 📝 Daily Survey         │   │
│  │ Answer 5 quick questions│   │
│  │ ⏱️ 1 min  |  💰 ₹0.10   │   │
│  │ [Start Task] →          │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ 📱 Share & Earn         │   │
│  │ Share app with friends  │   │
│  │ ⏱️ 30 sec |  💰 ₹0.10   │   │
│  │ [Start Task] →          │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ ⭐ Rate Us              │   │
│  │ Rate us on Play Store   │   │
│  │ ⏱️ 1 min  |  💰 ₹0.10   │   │
│  │ [Start Task] →          │   │
│  └─────────────────────────┘   │
│                                 │
│  ─── Completed Today ───        │
│                                 │
│  ✅ Survey #1 - ₹0.10 earned   │
│                                 │
│  [Native Ad]                    │
│                                 │
└─────────────────────────────────┘
```

**Task Flow:**

1. User taps "Start Task"
2. Show rewarded ad (required)
3. After ad: Navigate to task screen
4. Complete task
5. Validate completion on backend
6. Show success animation + earnings
7. Update balance
8. Show "Watch bonus ad for +₹0.03?" popup

**Validation Rules:**
- Survey: All questions must be answered
- Social Share: Screenshot upload + manual review (24h)
- Rating: Deep link to Play Store, verify via API

---

### 6.6 Games Screen

**Available Games:**

1. **Tic-Tac-Toe (₹0.08 per win)**
   - Play against AI (medium difficulty)
   - 30-minute cooldown between plays
   - Interstitial ad before game
   - Rewarded ad to claim winnings

2. **Memory Match (₹0.08 per completion)**
   - 4×4 grid (16 cards)
   - Match 8 pairs
   - Time limit: 90 seconds
   - Rewarded ad to claim winnings

**Games Screen UI:**

```
┌─────────────────────────────────┐
│ ← Games                         │
├─────────────────────────────────┤
│                                 │
│  🎮 Play & Earn                 │
│  [Progress: 2/6 games today]    │
│                                 │
│  ─── Available Games ───        │
│                                 │
│  ┌─────────────────────────┐   │
│  │ ❌⭕ Tic-Tac-Toe        │   │
│  │ Beat the AI to win!     │   │
│  │                         │   │
│  │ 💰 ₹0.08 per win        │   │
│  │ ⏱️ Ready to play        │   │
│  │                         │   │
│  │     [Play Now]          │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ 🧠 Memory Match         │   │
│  │ Find all pairs quickly! │   │
│  │                         │   │
│  │ 💰 ₹0.08 per game       │   │
│  │ ⏱️ Next play in 15 min  │   │ // Cooldown
│  │                         │   │
│  │     [⏱️ Cooldown]       │   │ // Disabled
│  └─────────────────────────┘   │
│                                 │
│  ─── Today's Best Scores ───    │
│                                 │
│  🥇 Rajesh K. - 45 sec          │
│  🥈 Priya S. - 52 sec           │
│  🥉 You - 67 sec                │
│                                 │
│  [View Leaderboard]             │
│                                 │
└─────────────────────────────────┘
```

**Tic-Tac-Toe Game Screen:**

```
┌─────────────────────────────────┐
│ ← Quit              ⏱️ 00:45    │
├─────────────────────────────────┤
│                                 │
│         Tic-Tac-Toe             │
│                                 │
│     You: X  |  AI: O            │
│                                 │
│        ┌───┬───┬───┐            │
│        │ X │   │ O │            │
│        ├───┼───┼───┤            │
│        │   │ X │   │            │
│        ├───┼───┼───┤            │
│        │ O │   │   │            │
│        └───┴───┴───┘            │
│                                 │
│      Your turn! Tap to place X  │
│                                 │
└─────────────────────────────────┘
```

**Win/Lose Flow:**

**Win:**
```
┌─────────────────────────────────┐
│                                 │
│          🎉 You Won! 🎉         │
│                                 │
│     [Animation: Confetti]       │
│                                 │
│    You've earned ₹0.08!         │
│                                 │
│    Watch an ad to claim?        │
│                                 │
│    [Watch Ad & Claim] ✅        │
│    [Skip (Forfeit Earnings)]    │
│                                 │
└─────────────────────────────────┘
```

**Lose:**
```
┌─────────────────────────────────┐
│                                 │
│          😔 AI Wins             │
│                                 │
│    Better luck next time!       │
│                                 │
│    Next play available in:      │
│         ⏱️ 29:45               │
│                                 │
│    [Try Again Later]            │
│    [Play Different Game]        │
│                                 │
└─────────────────────────────────┘
```

**Memory Match Game Screen:**

```
┌─────────────────────────────────┐
│ ← Quit    ⏱️ 01:15    Pairs: 3/8│
├─────────────────────────────────┤
│                                 │
│       🧠 Memory Match            │
│                                 │
│    ┌────┬────┬────┬────┐        │
│    │ 🍎 │ ❓ │ 🍌 │ ❓ │        │
│    ├────┼────┼────┼────┤        │
│    │ ❓ │ 🍎 │ ❓ │ 🍊 │        │
│    ├────┼────┼────┼────┤        │
│    │ 🍌 │ ❓ │ 🍇 │ ❓ │        │
│    ├────┼────┼────┼────┤        │
│    │ ❓ │ 🍇 │ ❓ │ 🍊 │        │
│    └────┴────┴────┴────┘        │
│                                 │
│    Tap cards to flip and match! │
│                                 │
└─────────────────────────────────┘
```

**Game Validation (Anti-Cheat):**

```typescript
// Backend validation
function validateGameResult(gameData) {
  const {
    userId,
    gameType,
    score,
    duration,
    moves,
    timestamp
  } = gameData;
  
  // Check if humanly possible
  if (gameType === 'memory') {
    const minPossibleTime = 20; // 20 seconds minimum
    if (duration < minPossibleTime) {
      return { valid: false, reason: 'Too fast' };
    }
  }
  
  if (gameType === 'tictactoe') {
    const minMoves = 5;
    if (moves < minMoves) {
      return { valid: false, reason: 'Invalid game' };
    }
  }
  
  // Check cooldown
  const lastPlay = await getLastGamePlay(userId, gameType);
  if (timestamp - lastPlay < COOLDOWN_MS) {
    return { valid: false, reason: 'Cooldown active' };
  }
  
  return { valid: true };
}
```

---

### 6.7 Spin & Win Screen

**Mechanics:**
- 1 free spin per day
- Must watch rewarded ad to unlock spin
- Wheel has 8 segments:
  - ₹0.05 (30% chance)
  - ₹0.10 (25% chance)
  - ₹0.20 (20% chance)
  - ₹0.50 (15% chance)
  - ₹1.00 (5% chance)
  - 2x Multiplier for next task (3% chance)
  - Bonus game unlock (1.5% chance)
  - Extra spin (0.5% chance)

**UI:**

```
┌─────────────────────────────────┐
│ ← Spin & Win                    │
├─────────────────────────────────┤
│                                 │
│       🎰 Daily Spin Wheel       │
│                                 │
│    Today's Spins: 0/1           │
│                                 │
│         [Spinning Wheel         │
│          Animation with         │
│          8 colored segments     │
│          showing prizes]        │
│                                 │
│      ⏰ Next spin in: 18h 23m   │
│                                 │
│    ┌─────────────────────┐     │
│    │  Watch ad to spin!  │     │
│    │                     │     │
│    │   [Watch & Spin] 📺 │     │
│    └─────────────────────┘     │
│                                 │
│  ─── Recent Winners ───         │
│  • Amit K. won ₹1.00            │
│  • Sneha P. won ₹0.50           │
│  • You won ₹0.20 yesterday      │
│                                 │
└─────────────────────────────────┘
```

**Spin Animation:**
- 3-second spin with deceleration
- Haptic feedback during spin
- Sound effects (optional, user toggle)
- Confetti on high-value wins

**Backend Logic:**

```typescript
function generateSpinResult(userId) {
  const random = Math.random() * 100;
  
  let prize;
  if (random < 30) prize = { type: 'cash', amount: 0.05 };
  else if (random < 55) prize = { type: 'cash', amount: 0.10 };
  else if (random < 75) prize = { type: 'cash', amount: 0.20 };
  else if (random < 90) prize = { type: 'cash', amount: 0.50 };
  else if (random < 95) prize = { type: 'cash', amount: 1.00 };
  else if (random < 98) prize = { type: 'multiplier', value: 2 };
  else if (random < 99.5) prize = { type: 'bonus_game' };
  else prize = { type: 'extra_spin' };
  
  // Log to prevent manipulation
  await logSpin(userId, prize, timestamp);
  
  return prize;
}
```

---

### 6.8 Watch Ads Screen

**Purpose:** Optional bonus earning through ad watching

**UI:**

```
┌─────────────────────────────────┐
│ ← Watch & Earn                  │
├─────────────────────────────────┤
│                                 │
│     📺 Watch Ads to Earn        │
│                                 │
│  ┌───────────────────────┐     │
│  │  Today: 2/5 ads       │     │
│  │  Earned: ₹0.06        │     │
│  │  [Progress Bar]       │     │
│  └───────────────────────┘     │
│                                 │
│  ─── Available Ads ───          │
│                                 │
│  ┌─────────────────────────┐   │
│  │ 📱 Brand Video Ad #1    │   │
│  │ 30 seconds              │   │
│  │                         │   │
│  │ Earn: ₹0.03             │   │
│  │ [Watch Now] ▶️          │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ 🎮 Game Ad #2           │   │
│  │ 30 seconds              │   │
│  │                         │   │
│  │ Earn: ₹0.03             │   │
│  │ [Watch Now] ▶️          │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ 🛒 Shopping Ad #3       │   │
│  │ 30 seconds              │   │
│  │                         │   │
│  │ Earn: ₹0.03             │   │
│  │ [Watch Now] ▶️          │   │
│  └─────────────────────────┘   │
│                                 │
│  ⏱️ Daily limit resets in: 6h  │
│                                 │
└─────────────────────────────────┘
```

**Ad Watching Flow:**

1. User taps "Watch Now"
2. Show AdMob rewarded ad
3. Track ad completion (AdMob callback)
4. If completed (>80% watched):
   - Credit ₹0.03 to balance
   - Show success toast
   - Update UI
5. If skipped/failed:
   - Show "Ad not completed" message
   - No earnings
6. 30-second cooldown before next ad

**Backend Tracking:**

```typescript
async function trackAdWatch(userId, adUnitId, completed) {
  if (!completed) return { error: 'Ad not completed' };
  
  const today = await getUserLimits(userId);
  
  if (today.adsWatched >= 5) {
    return { error: 'Daily ad limit reached' };
  }
  
  // Credit earnings
  await creditEarnings(userId, 0.03, 'bonus_ad');
  
  // Update limits
  await incrementAdCount(userId);
  
  return {
    success: true,
    earned: 0.03,
    remaining: 5 - today.adsWatched - 1
  };
}
```

---

### 6.9 Leaderboard Screen

**Features:**
- Top 50 users by lifetime earnings
- User's current rank
- Updated every 10 minutes (cached)
- Anonymous display names (first name + last initial)

**UI:**

```
┌─────────────────────────────────┐
│ ← Leaderboard            [🔄]  │
├─────────────────────────────────┤
│                                 │
│     🏆 Top Earners              │
│                                 │
│  ┌───────────────────────┐     │
│  │  Your Rank: #127      │     │
│  │  Total Earned: ₹2.50  │     │
│  └───────────────────────┘     │
│                                 │
│  ─── Top 50 ───                 │
│                                 │
│  ┌─────────────────────────┐   │
│  │ 🥇 1. Rahul K.          │   │
│  │    ₹245.50  →          │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ 🥈 2. Priya S.          │   │
│  │    ₹238.20  →          │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ 🥉 3. Amit P.           │   │
│  │    ₹232.80  →          │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ 4. Sneha M.             │   │
│  │    ₹198.40              │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ 5. Vikram R.            │   │
│  │    ₹187.60              │   │
│  └─────────────────────────┘   │
│                                 │
│  [Load More...]                 │
│                                 │
│  [Native Ad]                    │
│                                 │
│  Last updated: 5 mins ago       │
│                                 │
└─────────────────────────────────┘
```

**Caching Strategy:**

```typescript
// Cloudflare Worker with KV cache
async function getLeaderboard(userId) {
  const cacheKey = 'leaderboard:top50';
  
  // Check cache (5 min TTL)
  let leaderboard = await KV.get(cacheKey, { type: 'json' });
  
  if (!leaderboard) {
    // Query Firestore
    leaderboard = await db
      .collection('leaderboard')
      .orderBy('totalEarned', 'desc')
      .limit(50)
      .get();
    
    // Cache result
    await KV.put(cacheKey, JSON.stringify(leaderboard), {
      expirationTtl: 300 // 5 minutes
    });
  }
  
  // Get user's rank separately
  const userRank = await getUserRank(userId);
  
  return {
    leaderboard,
    userRank,
    lastUpdated: new Date()
  };
}
```

**Privacy:**
- Only show first name + last initial
- No profile pictures in leaderboard
- Option to hide from leaderboard in settings

---

### 6.10 Invite & Referral Screen

**Referral Mechanics:**
- Each user gets unique 6-character code
- Referrer earns ₹2 when referee earns ₹10
- Referee gets ₹0.50 signup bonus
- Max 50 referrals per user

**UI:**

```
┌─────────────────────────────────┐
│ ← Invite Friends                │
├─────────────────────────────────┤
│                                 │
│   👥 Invite & Earn Together     │
│                                 │
│  ┌───────────────────────┐     │
│  │  Your Referral Code   │     │
│  │                       │     │
│  │      EARN2K           │     │ // Large, copyable
│  │                       │     │
│  │  [Copy Code] 📋       │     │
│  └───────────────────────┘     │
│                                 │
│  ─── How It Works ───           │
│                                 │
│  1️⃣ Share your code            │
│  2️⃣ Friend signs up & earns ₹10│
│  3️⃣ You get ₹2!                │
│                                 │
│  ─── Share Via ───              │
│                                 │
│  [WhatsApp] [Instagram] [Copy] │
│                                 │
│  ─── Your Referrals ───         │
│                                 │
│  Total Referred: 3              │
│  Earned from Referrals: ₹4.00  │
│                                 │
│  ┌─────────────────────────┐   │
│  │ ✅ Rajesh K.            │   │
│  │    Earned you ₹2.00     │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ ⏳ Priya S.             │   │
│  │    ₹6.50 / ₹10.00      │   │ // Progress
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ ⏳ Amit P.              │   │
│  │    ₹2.00 / ₹10.00      │   │
│  └─────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

**Share Message Template:**

```
Hey! 👋

I'm earning real money on EarnQuest by playing games and completing simple tasks. Join me and get ₹0.50 signup bonus!

Use my code: EARN2K

Download: [Play Store Link]

Let's earn together! 💰
```

**Backend Validation:**

```typescript
async function processReferral(refereeId, referrerCode) {
  // Validate referrer code
  const referrer = await getUserByReferralCode(referrerCode);
  if (!referrer) return { error: 'Invalid code' };
  
  // Check if referee already used a code
  const referee = await getUser(refereeId);
  if (referee.referral.referredBy) {
    return { error: 'Already used a referral code' };
  }
  
  // Check referrer limit
  if (referrer.referral.referralCount >= 50) {
    return { error: 'Referrer limit reached' };
  }
  
  // Apply signup bonus to referee
  await creditEarnings(refereeId, 0.50, 'signup_bonus');
  
  // Link referee to referrer
  await updateUser(refereeId, {
    'referral.referredBy': referrer.userId
  });
  
  // Track for future payout
  await createPendingReferral(referrer.userId, refereeId);
  
  return { success: true };
}

// When referee earns ₹10
async function checkReferralPayout(refereeId) {
  const referee = await getUser(refereeId);
  
  if (referee.earnings.totalEarned >= 10.00 && 
      referee.referral.referredBy &&
      !referee.referral.payoutProcessed) {
    
    const referrerId = referee.referral.referredBy;
    
    // Credit referrer
    await creditEarnings(referrerId, 2.00, 'referral_bonus');
    
    // Mark as processed
    await updateUser(refereeId, {
      'referral.payoutProcessed': true
    });
    
    // Send notification to referrer
    await sendNotification(referrerId, 
      'Referral earned!', 
      'You earned ₹2 from your referral!'
    );
  }
}
```

---

### 6.11 Withdrawal Screen

**Requirements:**
- Minimum withdrawal: ₹50
- UPI only (Indian users)
- Processing time: 24-48 hours
- Max 1 withdrawal per week
- KYC required for lifetime withdrawals >₹100

**UI:**

```
┌─────────────────────────────────┐
│ ← Withdraw                      │
├─────────────────────────────────┤
│                                 │
│     💰 Cash Out                 │
│                                 │
│  ┌───────────────────────┐     │
│  │  Available Balance    │     │
│  │      ₹52.50           │     │
│  └───────────────────────┘     │
│                                 │
│  ─── Withdrawal Details ───     │
│                                 │
│  Enter Amount                   │
│  ┌─────────────────────────┐   │
│  │ ₹ [50.00]              │   │ // Input field
│  └─────────────────────────┘   │
│  Min: ₹50 | Max: ₹52.50        │
│                                 │
│  UPI ID                         │
│  ┌─────────────────────────┐   │
│  │ [yourname@paytm]       │   │
│  └─────────────────────────┘   │
│                                 │
│  ℹ️ Processing Time: 24-48 hours│
│                                 │
│  ┌─────────────────────────┐   │
│  │   [Request Withdrawal]  │   │ // Primary button
│  └─────────────────────────┘   │
│                                 │
│  ─── Recent Withdrawals ───     │
│                                 │
│  ✅ ₹50.00 - Completed          │
│     Nov 15, 2025                │
│                                 │
│  ⏳ ₹50.00 - Processing         │
│     Nov 18, 2025                │
│                                 │
│  [Native Ad]                    │
│                                 │
└─────────────────────────────────┘
```

**KYC Screen (triggered at >₹100 lifetime):**

```
┌─────────────────────────────────┐
│ ← KYC Verification              │
├─────────────────────────────────┤
│                                 │
│   🔐 Verify Your Identity       │
│                                 │
│   To withdraw amounts over ₹100,│
│   we need to verify your identity│
│                                 │
│  Full Name                      │
│  ┌─────────────────────────┐   │
│  │ [Enter full name]       │   │
│  └─────────────────────────┘   │
│                                 │
│  Phone Number                   │
│  ┌─────────────────────────┐   │
│  │ +91 [9876543210]        │   │
│  └─────────────────────────┘   │
│                                 │
│  [Send OTP]                     │
│                                 │
│  UPI ID                         │
│  ┌─────────────────────────┐   │
│  │ [yourname@paytm]        │   │
│  └─────────────────────────┘   │
│                                 │
│  ℹ️ Your information is secure  │
│     and encrypted               │
│                                 │
│  [Complete Verification]        │
│                                 │
└─────────────────────────────────┘
```

**Withdrawal Validation (Backend):**

```typescript
async function requestWithdrawal(userId, amount, upiId) {
  const user = await getUser(userId);
  
  // Check balance
  if (user.earnings.availableBalance < amount) {
    return { error: 'Insufficient balance' };
  }
  
  // Check minimum
  if (amount < 50) {
    return { error: 'Minimum withdrawal is ₹50' };
  }
  
  // Check maximum (available balance)
  if (amount > user.earnings.availableBalance) {
    return { error: 'Amount exceeds available balance' };
  }
  
  // Check weekly limit
  const lastWithdrawal = await getLastWithdrawal(userId);
  if (lastWithdrawal && 
      Date.now() - lastWithdrawal.timestamp < 7 * 24 * 60 * 60 * 1000) {
    return { error: 'Only 1 withdrawal per week allowed' };
  }
  
  // Check KYC
  const lifetimeWithdrawn = user.earnings.lifetimeWithdrawn;
  if (lifetimeWithdrawn + amount > 100 && !user.kyc.verified) {
    return { error: 'KYC required for withdrawals over ₹100 lifetime' };
  }
  
  // Fraud checks
  const accountAge = Date.now() - user.createdAt;
  if (accountAge < 7 * 24 * 60 * 60 * 1000) {
    return { error: 'Account must be at least 7 days old' };
  }
  
  if (user.stats.totalTasksCompleted < 20) {
    return { error: 'Complete at least 20 tasks before withdrawal' };
  }
  
  if (user.security.suspiciousActivity || user.security.accountLocked) {
    return { error: 'Account under review. Contact support.' };
  }
  
  // Create withdrawal request
  const withdrawalId = generateId();
  await createWithdrawal({
    withdrawalId,
    userId,
    amount,
    upiId,
    status: 'pending',
    requestedAt: Date.now()
  });
  
  // Deduct from available balance
  await updateUser(userId, {
    'earnings.availableBalance': user.earnings.availableBalance - amount,
    'earnings.pendingWithdrawal': user.earnings.pendingWithdrawal + amount
  });
  
  // Log transaction
  await createTransaction({
    userId,
    type: 'withdrawal',
    amount: -amount,
    status: 'pending',
    metadata: { withdrawalId }
  });
  
  return {
    success: true,
    withdrawalId,
    estimatedTime: '24-48 hours'
  };
}
```

**Manual Review Process:**
- All first-time withdrawals >₹50: Manual review
- Check for duplicate accounts (same device/IP)
- Verify task completion patterns
- Review ad watch timing
- Check UPI ID validity
- Approve/reject within 24 hours

---

### 6.12 Profile Screen

**UI:**

```
┌─────────────────────────────────┐
│ ← Profile                  [⚙️] │
├─────────────────────────────────┤
│                                 │
│     [Profile Picture]           │
│     Rahul Kumar                 │
│     rahul.k@gmail.com           │
│                                 │
│  ┌───────────────────────┐     │
│  │ 🔥 7-Day Streak       │     │
│  │ 💰 ₹52.50 Total       │     │
│  │ 🏆 Rank #127          │     │
│  └───────────────────────┘     │
│                                 │
│  ─── Statistics ───             │
│                                 │
│  📊 Total Earned                │
│      ₹52.50                     │
│                                 │
│  💸 Withdrawn                   │
│      ₹0.00                      │
│                                 │
│  📺 Ads Watched                 │
│      245 ads                    │
│                                 │
│  ✅ Tasks Completed             │
│      89 tasks                   │
│                                 │
│  🎮 Games Played                │
│      156 games                  │
│                                 │
│  👥 Referrals                   │
│      3 friends                  │
│                                 │
│  📅 Member Since                │
│      Oct 15, 2025               │
│                                 │
│  ─── Quick Actions ───          │
│                                 │
│  [Edit Profile]                 │
│  [Referral Program]             │
│  [Withdrawal History]           │
│  [Help & Support]               │
│  [Privacy Policy]               │
│  [Terms of Service]             │
│                                 │
│  [Logout]                       │
│                                 │
└─────────────────────────────────┘
```

**Settings Screen:**

```
┌─────────────────────────────────┐
│ ← Settings                      │
├─────────────────────────────────┤
│                                 │
│  ─── Notifications ───          │
│                                 │
│  Daily Reminders      [Toggle]  │
│  Streak Alerts        [Toggle]  │
│  Withdrawal Updates   [Toggle]  │
│  Promotional Offers   [Toggle]  │
│                                 │
│  ─── Privacy ───                │
│                                 │
│  Show on Leaderboard  [Toggle]  │
│  Share Analytics      [Toggle]  │
│                                 │
│  ─── Preferences ───            │
│                                 │
│  Sound Effects        [Toggle]  │
│  Haptic Feedback      [Toggle]  │
│  Dark Mode            [Toggle]  │
│                                 │
│  ─── Account ───                │
│                                 │
│  Change Password                │
│  Update UPI ID                  │
│  Delete Account                 │
│                                 │
│  ─── About ───                  │
│                                 │
│  Version: 1.0.0                 │
│  [Rate Us on Play Store]        │
│  [Contact Support]              │
│                                 │
└─────────────────────────────────┘
```

---

### 6.13 Notifications System

**Local Notifications (No FCM needed):**

1. **Daily Reminder (9 AM)**
   - Title: "🌅 Good Morning!"
   - Body: "Complete today's tasks and earn up to ₹1.50"
   - Action: Opens Home screen

2. **Streak Alert (if user didn't open app today, 8 PM)**
   - Title: "🔥 Don't Break Your Streak!"
   - Body: "You're on a 7-day streak. Open now to maintain it!"
   - Action: Opens Home screen

3. **Withdrawal Update**
   - Title: "💰 Withdrawal Processed"
   - Body: "Your ₹50 withdrawal has been completed!"
   - Action: Opens Withdrawal screen

4. **Referral Success**
   - Title: "🎉 Referral Earned!"
   - Body: "Your friend completed ₹10. You earned ₹2!"
   - Action: Opens Invite screen

5. **Daily Spin Available**
   - Title: "🎰 Daily Spin Ready!"
   - Body: "Spin the wheel for a chance to win up to ₹1!"
   - Action: Opens Spin screen

**Implementation:**

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications;
  
  // Schedule daily reminder
  Future<void> scheduleDailyReminder() async {
    await _notifications.zonedSchedule(
      0,
      '🌅 Good Morning!',
      'Complete today\'s tasks and earn up to ₹1.50',
      _nextInstanceOf(9, 0), // 9 AM
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminders',
          importance: Importance.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
  
  // Streak alert
  Future<void> scheduleStreakAlert() async {
    // Check if user opened app today
    final lastActive = await getLastActiveTime();
    if (!isToday(lastActive)) {
      await _notifications.zonedSchedule(
        1,
        '🔥 Don\'t Break Your Streak!',
        'You\'re on a ${currentStreak}-day streak. Open now!',
        _nextInstanceOf(20, 0), // 8 PM
        // ... notification details
      );
    }
  }
  
  // Instant notification
  Future<void> showWithdrawalSuccess(double amount) async {
    await _notifications.show(
      2,
      '💰 Withdrawal Processed',
      'Your ₹${amount.toStringAsFixed(2)} withdrawal has been completed!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'withdrawal_updates',
          'Withdrawal Updates',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}
```

---

### 6.14 Error & Edge Case Screens

**No Internet Connection:**

```
┌─────────────────────────────────┐
│                                 │
│         [Cloud Icon]            │
│                                 │
│    No Internet Connection       │
│                                 │
│  Please check your connection   │
│  and try again                  │
│                                 │
│     [Retry]                     │
│                                 │
│  ─── Offline Features ───       │
│  • View cached earnings         │
│  • Play offline games (soon)    │
│                                 │
└─────────────────────────────────┘
```

**Daily Limit Reached:**

```
┌─────────────────────────────────┐
│                                 │
│      [Trophy Icon]              │
│                                 │
│  🎉 Daily Goal Reached!         │
│                                 │
│  You've earned ₹1.50 today.     │
│  Come back tomorrow for more!   │
│                                 │
│  Next reset in: 6h 23m          │
│                                 │
│  [View Leaderboard]             │
│  [Invite Friends]               │
│                                 │
└─────────────────────────────────┘
```

**Account Locked (Fraud Detected):**

```
┌─────────────────────────────────┐
│                                 │
│      [Lock Icon]                │
│                                 │
│    Account Under Review         │
│                                 │
│  We've detected suspicious      │
│  activity on your account.      │
│                                 │
│  Our team is reviewing your     │
│  account. This usually takes    │
│  24-48 hours.                   │
│                                 │
│  If you believe this is a       │
│  mistake, please contact us:    │
│                                 │
│  [Contact Support]              │
│                                 │
└─────────────────────────────────┘
```

**Maintenance Mode:**

```
┌─────────────────────────────────┐
│                                 │
│      [Wrench Icon]              │
│                                 │
│    We're Upgrading!             │
│                                 │
│  EarnQuest is currently under   │
│  maintenance to bring you       │
│  better features.               │
│                                 │
│  We'll be back in: 2 hours      │
│                                 │
│  Don't worry, your earnings     │
│  are safe! 💰                   │
│                                 │
└─────────────────────────────────┘
```

---

## 7. User Flows & Journeys

### 7.1 New User Onboarding Flow

```
First Launch
    ↓
Splash Screen (2s)
    ↓
Onboarding Slides (3 screens)
    ↓
"Get Started" Button
    ↓
Sign Up Screen
    ↓
Email/Password OR Google Sign-In
    ↓
[If Referral Code] Enter Code
    ↓
Account Created (₹0.50 signup bonus if referred)
    ↓
Home Screen Tutorial
    ↓
"Complete Your First Task" Prompt
    ↓
Watch Rewarded Ad
    ↓
Complete Task
    ↓
Success! ₹0.10 Earned (Confetti Animation)
    ↓
"Watch Bonus Ad?" Popup
    ↓
[If Yes] +₹0.03
    ↓
Home Screen (Balance: ₹0.13 or ₹0.63 if referred)
```

### 7.2 Daily Active User Flow

```
App Open (9 AM Daily Notification)
    ↓
App Open Ad
    ↓
Home Screen
    ↓
Check Streak (Day 5 🔥)
    ↓
View Today's Progress (0/₹1.50)
    ↓
─── Task Flow ───
    ↓
Tap "Tasks" Card
    ↓
Select Daily Survey
    ↓
Watch Rewarded Ad (Required)
    ↓
Answer 5 Questions
    ↓
Submit + Watch Claim Ad
    ↓
Earn ₹0.10 ✓
    ↓
Return to Home
    ↓
─── Game Flow ───
    ↓
Tap "Games" Card
    ↓
Select Tic-Tac-Toe
    ↓
Interstitial Ad
    ↓
Play Game (2 min)
    ↓
Win!
    ↓
Watch Rewarded Ad to Claim
    ↓
Earn ₹0.08 ✓
    ↓
Return to Home
    ↓
─── Spin Flow ───
    ↓
Tap "Spin & Win"
    ↓
Watch Rewarded Ad to Unlock
    ↓
Spin Wheel (3s animation)
    ↓
Win ₹0.20 🎉
    ↓
Return to Home
    ↓
─── Bonus Ads ───
    ↓
Tap "Watch Ads" Card
    ↓
Watch 3 Bonus Ads (3 × ₹0.03)
    ↓
Earn ₹0.09 ✓
    ↓
Total Earned Today: ₹0.47
    ↓
Check Leaderboard (Rank #125 → #122)
    ↓
Exit App
```

### 7.3 Withdrawal Flow

```
User Balance: ₹52.50
    ↓
Tap "Withdraw" on Home Screen
    ↓
Withdrawal Screen
    ↓
Enter Amount (₹50.00)
    ↓
Enter/Confirm UPI ID
    ↓
[If First Time] Enter Full Name & Phone for KYC
    ↓
Review Details
    ↓
Tap "Request Withdrawal"
    ↓
Backend Validation (Device, IP, Fraud Check)
    ↓
[If Approved] Success Screen
    ↓
"Processing in 24-48 hours" Message
    ↓
Balance Updated: ₹2.50 (Available) + ₹50.00 (Pending)
    ↓
Email/SMS Confirmation Sent
    ↓
[24-48 Hours Later]
    ↓
Manual Admin Review
    ↓
[If Approved] UPI Transfer Initiated
    ↓
[If Completed] Update Status to "Completed"
    ↓
Send Push Notification: "Withdrawal Processed"
    ↓
User Sees: "✅ ₹50.00 - Completed"
```

### 7.4 Referral Flow

```
User A (Referrer)
    ↓
Tap "Invite Friends"
    ↓
Copy Referral Code: EARN2K
    ↓
Share via WhatsApp to User B
    ↓
──────────────────
    ↓
User B (Referee) Receives Link
    ↓
Downloads App
    ↓
Sign Up Screen
    ↓
Auto-fills Referral Code: EARN2K
    ↓
Completes Sign Up
    ↓
Immediate Credit: ₹0.50 Signup Bonus
    ↓
Notification: "You got ₹0.50 from your friend!"
    ↓
──────────────────
    ↓
User B Earns Over Time
    ↓
Completes Tasks & Games
    ↓
Total Earned: ₹10.00 (Threshold Met)
    ↓
Backend Triggers Referral Payout
    ↓
User A Gets: ₹2.00 Referral Bonus
    ↓
Notification to User A: "Referral earned! +₹2"
    ↓
User A sees in Referral Screen:
    "✅ User B - Earned you ₹2.00"
```

---

## 8. Backend Architecture Deep Dive

### 8.1 Cloudflare Workers Structure

**Worker Entry Point (index.js):**

```typescript
import { Router } from 'itty-router';
import { validateRequest } from './middleware/auth';
import { rateLimiter } from './middleware/rateLimit';
import { corsHeaders } from './middleware/cors';

const router = Router();

// Middleware
router.all('*', corsHeaders);
router.all('/api/*', rateLimiter);
router.all('/api/*', validateRequest);

// Routes
router.post('/api/earn/task', handleTaskEarn);
router.post('/api/earn/game', handleGameEarn);
router.post('/api/earn/ad', handleAdEarn);
router.post('/api/spin', handleSpin);
router.get('/api/leaderboard', handleLeaderboard);
router.post('/api/withdrawal/request', handleWithdrawal);
router.get('/api/user/stats', handleUserStats);

// 404
router.all('*', () => new Response('Not Found', { status: 404 }));

export default {
  async fetch(request, env, ctx) {
    return router.handle(request, env, ctx);
  },
};
```

**Rate Limiter Middleware:**

```typescript
export async function rateLimiter(request, env) {
  const ip = request.headers.get('CF-Connecting-IP');
  const key = `ratelimit:${ip}`;
  
  const count = await env.KV.get(key);
  
  if (count && parseInt(count) > 100) {
    return new Response('Rate limit exceeded', { status: 429 });
  }
  
  // Increment
  const newCount = count ? parseInt(count) + 1 : 1;
  await env.KV.put(key, newCount.toString(), { expirationTtl: 60 });
}
```

**Auth Middleware:**

```typescript
import { initializeApp, cert } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

export async function validateRequest(request, env) {
  const authHeader = request.headers.get('Authorization');
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return new Response('Unauthorized', { status: 401 });
  }
  
  const token = authHeader.split('Bearer ')[1];
  
  try {
    const decodedToken = await getAuth().verifyIdToken(token);
    request.userId = decodedToken.uid;
  } catch (error) {
    return new Response('Invalid token', { status: 401 });
  }
}
```

**Task Earn Handler:**

```typescript
export async function handleTaskEarn(request, env) {
  const { userId, taskId, completionProof, deviceId } = await request.json();
  
  // Validate daily limits
  const limits = await getUserLimits(env, userId);
  
  if (limits.todayTasksCompleted >= 3) {
    return jsonResponse({ error: 'Daily task limit reached' }, 429);
  }
  
  if (limits.todayEarnings >= 1.50) {
    return jsonResponse({ error: 'Daily earning limit reached' }, 429);
  }
  
  // Validate task completion
  const isValid = await validateTaskCompletion(taskId, completionProof);
  if (!isValid) {
    return jsonResponse({ error: 'Invalid task completion' }, 400);
  }
  
  // Check fraud
  const fraudCheck = await checkFraud(userId, deviceId, 'task');
  if (fraudCheck.suspicious) {
    await flagAccount(userId);
    return jsonResponse({ error: 'Suspicious activity detected' }, 403);
  }
  
  // Credit earnings
  const earnAmount = 0.10;
  const result = await creditEarnings(env, userId, earnAmount, 'task', {
    taskId,
    deviceId,
  });
  
  // Update limits
  await incrementTaskCount(env, userId);
  
  return jsonResponse({
    success: true,
    earned: earnAmount,
    newBalance: result.newBalance,
    limits: {
      todayTasksRemaining: 3 - limits.todayTasksCompleted - 1,
      todayEarningsRemaining: 1.50 - limits.todayEarnings - earnAmount,
    },
  });
}
```

**Credit Earnings Function:**

```typescript
async function creditEarnings(env, userId, amount, source, metadata) {
  // Get current balance from Firestore
  const userRef = db.collection('users').doc(userId);
  const userDoc = await userRef.get();
  const userData = userDoc.data();
  
  const newBalance = userData.earnings.availableBalance + amount;
  const newTotalEarned = userData.earnings.totalEarned + amount;
  
  // Update user document
  await userRef.update({
    'earnings.availableBalance': newBalance,
    'earnings.totalEarned': newTotalEarned,
    'limits.todayEarnings': userData.limits.todayEarnings + amount,
  });
  
  // Create transaction record
  await db.collection('transactions').add({
    userId,
    type: 'earn',
    amount,
    source,
    status: 'completed',
    metadata,
    timestamp: new Date(),
  });
  
  // Update leaderboard (async)
  await updateLeaderboard(userId, newTotalEarned);
  
  return { newBalance, newTotalEarned };
}
```

**Fraud Detection:**

```typescript
async function checkFraud(userId, deviceId, activityType) {
  const checks = [];
  
  // Check 1: Multiple accounts per device
  const deviceAccounts = await db
    .collection('users')
    .where('security.deviceId', '==', deviceId)
    .get();
  
  if (deviceAccounts.size > 2) {
    checks.push({ type: 'multiple_accounts', severity: 'high' });
  }
  
  // Check 2: Velocity check
  const recentActivity = await db
    .collection('transactions')
    .where('userId', '==', userId)
    .where('timestamp', '>', new Date(Date.now() - 5 * 60 * 1000))
    .get();
  
  if (recentActivity.size > 10) {
    checks.push({ type: 'high_velocity', severity: 'medium' });
  }
  
  // Check 3: Impossible timing
  if (activityType === 'task') {
    const lastTask = recentActivity.docs[0];
    if (lastTask && Date.now() - lastTask.data().timestamp < 5000) {
      checks.push({ type: 'impossible_timing', severity: 'high' });
    }
  }
  
  const highSeverityCount = checks.filter(c => c.severity === 'high').length;
  
  return {
    suspicious: highSeverityCount > 0,
    checks,
    action: highSeverityCount > 1 ? 'block' : 'flag',
  };
}
```

### 8.2 Firestore Optimization Strategies

**Read Optimization:**

1. **Local Caching:**
```dart
// Cache user data for 2 minutes
class UserDataCache {
  static Map<String, CachedUser> _cache = {};
  
  static Future<User> getUser(String userId) async {
    final cached = _cache[userId];
    
    if (cached != null && 
        DateTime.now().difference(cached.timestamp).inMinutes < 2) {
      return cached.user;
    }
    
    // Fetch from Firestore
    final user = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    
    _cache[userId] = CachedUser(user.data(), DateTime.now());
    
    return user.data();
  }
}
```

2. **Batch Reads:**
```dart
// Instead of multiple single reads
final tasks = await getTasks();  // 1 read
final games = await getGames();  // 1 read
final ads = await getAds();      // 1 read

// Use a single query with subcollections cached locally
final homeData = await getHomeScreenData(); // 1 read
```

3. **Leaderboard Pagination:**
```dart
// Don't fetch all users at once
Query query = FirebaseFirestore.instance
    .collection('leaderboard')
    .orderBy('totalEarned', descending: true)
    .limit(50);  // Only top 50

// For user rank, use a separate cached query
```

**Write Optimization:**

1. **Batch Writes:**
```typescript
// Instead of 3 separate writes
await userRef.update({ ... });         // Write 1
await transactionRef.add({ ... });     // Write 2
await leaderboardRef.update({ ... });  // Write 3

// Use batch write (counts as 1 write per document, but faster)
const batch = db.batch();
batch.update(userRef, { ... });
batch.set(transactionRef, { ... });
batch.update(leaderboardRef, { ... });
await batch.commit();  // 3 writes total, but atomic
```

2. **Debounce Leaderboard Updates:**
```typescript
// Don't update leaderboard on every earn
// Instead, update every 10 minutes via scheduled job

export async function scheduledLeaderboardUpdate() {
  const usersToUpdate = await db
    .collection('users')
    .where('lastLeaderboardUpdate', '<', Date.now() - 10 * 60 * 1000)
    .limit(100)
    .get();
  
  const batch = db.batch();
  
  usersToUpdate.forEach(user => {
    batch.set(
      db.collection('leaderboard').doc(user.id),
      {
        userId: user.id,
        totalEarned: user.data().earnings.totalEarned,
        displayName: user.data().displayName,
        lastUpdated: Date.now(),
      },
      { merge: true }
    );
  });
  
  await batch.commit();
}
```

3. **Daily Limit Reset (Scheduled):**
```typescript
// Run daily at midnight via Cloudflare Cron Trigger
export async function resetDailyLimits() {
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  
  // Get all users who were active yesterday
  const activeUsers = await db
    .collection('users')
    .where('lastActive', '>', yesterday)
    .get();
  
  const batch = db.batch();
  
  activeUsers.forEach(user => {
    batch.update(db.collection('users').doc(user.id), {
      'limits.todayTasksCompleted': 0,
      'limits.todayAdsWatched': 0,
      'limits.todayGamesPlayed': 0,
      'limits.todayEarnings': 0,
      'limits.lastResetDate': new Date(),
    });
  });
  
  await batch.commit();
}
```

**Quota Management:**

```
Free Tier Limits:
- 50,000 reads/day
- 20,000 writes/day
- 20,000 deletes/day

For 10,000 users:
- Average 5 reads/user/day = 50,000 reads ✓
- Average 2 writes/user/day = 20,000 writes ✓

Breakdown per user per day:
Reads:
- App open: 1 read (user data)
- Home screen: 1 read (limits check)
- Task/game/ad: 3 reads (validation)
Total: 5 reads ✓

Writes:
- Earn activity: 1 write (update balance + limits)
- Transaction log: 1 write
Total: 2 writes ✓
```

---

## 9. Ad Integration Strategy

### 9.1 AdMob Setup

**Ad Unit IDs:**

```dart
class AdUnits {
  // Android
  static const androidAppOpen = 'ca-app-pub-3940256099942544/3419835294';
  static const androidRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const androidInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const androidNative = 'ca-app-pub-3940256099942544/2247696110';
  
  // iOS
  static const iosAppOpen = 'ca-app-pub-3940256099942544/5662855259';
  static const iosRewarded = 'ca-app-pub-3940256099942544/1712485313';
  static const iosInterstitial = 'ca-app-pub-3940256099942544/4411468910';
  static const iosNative = 'ca-app-pub-3940256099942544/3986624511';
}
```

**Ad Manager Class:**

```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  static RewardedAd? _rewardedAd;
  static InterstitialAd? _interstitialAd;
  static AppOpenAd? _appOpenAd;
  
  // Load rewarded ad
  static Future<void> loadRewardedAd() async {
    await RewardedAd.load(
      adUnitId: AdUnits.androidRewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          print('Rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          print('Rewarded ad failed: $error');
          // Retry after 30 seconds
          Future.delayed(Duration(seconds: 30), loadRewardedAd);
        },
      ),
    );
  }
  
  // Show rewarded ad
  static Future<bool> showRewardedAd({
    required Function onReward,
    required Function onAdClosed,
  }) async {
    if (_rewardedAd == null) {
      print('Rewarded ad not ready');
      return false;
    }
    
    bool rewarded = false;
    
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        onAdClosed();
        loadRewardedAd(); // Preload next ad
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        loadRewardedAd();
      },
    );
    
    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        rewarded = true;
        onReward();
      },
    );
    
    _rewardedAd = null;
    
    return rewarded;
  }
  
  // App Open Ad (on app launch)
  static Future<void> loadAppOpenAd() async {
    await AppOpenAd.load(
      adUnitId: AdUnits.androidAppOpen,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _appOpenAd!.show();
        },
        onAdFailedToLoad: (error) {
          print('App open ad failed: $error');
        },
      ),
      orientation: AppOpenAd.orientationPortrait,
    );
  }
  
  // Interstitial Ad
  static Future<void> showInterstitialAd() async {
    if (_interstitialAd != null) {
      await _interstitialAd!.show();
      _interstitialAd = null;
      loadInterstitialAd(); // Preload next
    }
  }
  
  static Future<void> loadInterstitialAd() async {
    await InterstitialAd.load(
      adUnitId: AdUnits.androidInterstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) {
          Future.delayed(Duration(seconds: 30), loadInterstitialAd);
        },
      ),
    );
  }
}
```

### 9.2 Ad Frequency & User Experience

**Ad Frequency Rules:**

1. **Rewarded Ads (User-Initiated):**
   - No frequency cap since user chooses to watch
   - Minimum 15 seconds between consecutive ads
   - Must watch 80%+ to count as complete

2. **Interstitial Ads (Auto-Shown):**
   - Max 1 per 5 minutes
   - Never show during active gameplay
   - Show after natural break points:
     - Between game rounds
     - After task completion
     - On screen transitions

3. **App Open Ads:**
   - Once per app session
   - Not on first-ever launch
   - Skip if last shown <4 hours ago

4. **Native Ads:**
   - Max 2 visible per screen
   - Labeled as "Sponsored"
   - Non-intrusive placement

**Ad Timing Strategy:**

```dart
class AdTimingManager {
  static DateTime? _lastInterstitialShown;
  static int _sessionAdCount = 0;
  
  static bool canShowInterstitial() {
    if (_lastInterstitialShown == null) return true;
    
    final timeSince = DateTime.now().difference(_lastInterstitialShown!);
    
    // Min 5 minutes between interstitials
    if (timeSince.inMinutes < 5) return false;
    
    // Max 3 interstitials per session
    if (_sessionAdCount >= 3) return false;
    
    return true;
  }
  
  static void recordInterstitialShown() {
    _lastInterstitialShown = DateTime.now();
    _sessionAdCount++;
  }
  
  static void resetSession() {
    _sessionAdCount = 0;
  }
}
```

### 9.3 Ad Revenue Tracking

**Track ad impressions and revenue:**

```dart
class AdAnalytics {
  static Future<void> trackAdImpression({
    required String adType,
    required String adUnitId,
    required String placement,
    double? estimatedRevenue,
  }) async {
    await FirebaseAnalytics.instance.logEvent(
      name: 'ad_impression',
      parameters: {
        'ad_type': adType,
        'ad_unit_id': adUnitId,
        'placement': placement,
        'estimated_revenue': estimatedRevenue ?? 0.0,
      },
    );
    
    // Also send to backend for tracking
    await ApiService.trackAd({
      'userId': currentUserId,
      'adType': adType,
      'placement': placement,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  static Future<void> trackAdClick(String adType) async {
    await FirebaseAnalytics.instance.logEvent(
      name: 'ad_click',
      parameters: {'ad_type': adType},
    );
  }
}
```

**Backend Ad Tracking:**

```typescript
// Track ad performance
async function trackAdPerformance(userId, adData) {
  const { adType, placement, revenue } = adData;
  
  // Update user ad stats
  await db.collection('users').doc(userId).update({
    'stats.totalAdsWatched': admin.firestore.FieldValue.increment(1),
  });
  
  // Aggregate daily stats
  const today = new Date().toISOString().split('T')[0];
  const statsRef = db.collection('ad_stats').doc(today);
  
  await statsRef.set({
    date: today,
    impressions: admin.firestore.FieldValue.increment(1),
    [`${adType}_impressions`]: admin.firestore.FieldValue.increment(1),
    estimated_revenue: admin.firestore.FieldValue.increment(revenue || 0),
  }, { merge: true });
}
```

---

## 10. Scaling Strategy for 10K Users on Free Tier

### 10.1 Resource Budgets

**Cloudflare Workers Free Tier:**
- 100,000 requests/day
- Budget per user: 10 requests/day
- Actual usage: 5-8 requests/day ✓

**Firebase Firestore Free Tier:**
- 50,000 reads/day
- 20,000 writes/day
- Budget: 5 reads + 2 writes per user/day ✓

**AdMob (No Limits):**
- Unlimited ad impressions
- Revenue scales with users ✓

### 10.2 Optimization Techniques

**1. Aggressive Caching:**

```dart
// Cache everything locally
class LocalCache {
  static final _prefs = SharedPreferences.getInstance();
  
  // Cache user data
  static Future<void> cacheUserData(User user) async {
    final prefs = await _prefs;
    await prefs.setString('user_data', jsonEncode(user.toJson()));
    await prefs.setInt('cache_timestamp', DateTime.now().millisecondsSinceEpoch);
  }
  
  // Get cached data if fresh
  static Future<User?> getCachedUser() async {
    final prefs = await _prefs;
    final cached = prefs.getString('user_data');
    final timestamp = prefs.getInt('cache_timestamp') ?? 0;
    
    // Cache valid for 2 minutes
    if (cached != null && 
        DateTime.now().millisecondsSinceEpoch - timestamp < 120000) {
      return User.fromJson(jsonDecode(cached));
    }
    
    return null;
  }
}
```

**2. Batch Operations:**

```typescript
// Instead of individual writes, batch them
const pendingWrites = [];

function queueWrite(collection, docId, data) {
  pendingWrites.push({ collection, docId, data });
  
  // Flush every 10 writes or every 5 seconds
  if (pendingWrites.length >= 10) {
    flushWrites();
  }
}

async function flushWrites() {
  if (pendingWrites.length === 0) return;
  
  const batch = db.batch();
  
  pendingWrites.forEach(({ collection, docId, data }) => {
    const ref = db.collection(collection).doc(docId);
    batch.set(ref, data, { merge: true });
  });
  
  await batch.commit();
  pendingWrites.length = 0;
}

// Scheduled flush every 5 seconds
setInterval(flushWrites, 5000);
```

**3. Read Reduction via Computed Fields:**

```typescript
// Instead of querying all transactions to calculate balance
// Store computed balance in user document

async function creditEarnings(userId, amount) {
  // Single write updates everything
  await db.collection('users').doc(userId).update({
    'earnings.availableBalance': admin.firestore.FieldValue.increment(amount),
    'earnings.totalEarned': admin.firestore.FieldValue.increment(amount),
    'stats.totalTransactions': admin.firestore.FieldValue.increment(1),
    lastUpdated: new Date(),
  });
  
  // Transaction log is separate (optional for analytics)
  await db.collection('transactions').add({
    userId,
    amount,
    type: 'earn',
    timestamp: new Date(),
  });
}
```

**4. Firestore Offline Persistence:**

```dart
// Enable offline persistence
await FirebaseFirestore.instance.enablePersistence();

// App works offline, syncs when online
final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .get();

// Returns cached data if offline
final userData = userDoc.data();
```

**5. Leaderboard Optimization:**

```typescript
// Only update leaderboard for top 100 users
// Others see estimated rank

async function updateLeaderboard(userId, totalEarned) {
  // Check if user is in top 100
  const topUsers = await db
    .collection('leaderboard')
    .orderBy('totalEarned', 'desc')
    .limit(100)
    .get();
  
  const lowestInTop100 = topUsers.docs[99]?.data()?.totalEarned || 0;
  
  if (totalEarned > lowestInTop100) {
    // User is in top 100, update immediately
    await db.collection('leaderboard').doc(userId).set({
      userId,
      totalEarned,
      lastUpdated: new Date(),
    }, { merge: true });
  }
  // Else: Don't update (saves writes)
}

// For users outside top 100, estimate rank
async function estimateRank(userId, totalEarned) {
  // Count users with higher earnings (cached query)
  const higherCount = await db
    .collection('users')
    .where('earnings.totalEarned', '>', totalEarned)
    .count()
    .get();
  
  return higherCount.data().count + 1;
}
```

**6. Scheduled Jobs vs Real-Time:**

```typescript
// Use Cloudflare Cron Triggers for non-critical updates

// Daily at midnight: Reset limits
export async function scheduled(event) {
  switch (event.cron) {
    case '0 0 * * *': // Midnight
      await resetDailyLimits();
      break;
    
    case '*/10 * * * *': // Every 10 minutes
      await updateLeaderboardCache();
      break;
    
    case '0 */6 * * *': // Every 6 hours
      await processWithdrawals();
      break;
  }
}
```

### 10.3 Monitoring & Alerts

**Quota Monitoring:**

```typescript
// Track Firestore usage
async function logQuotaUsage() {
  const stats = await admin.firestore()
    .collection('_system')
    .doc('quota_usage')
    .get();
  
  const { reads, writes } = stats.data();
  
  // Alert if approaching limits
  if (reads > 45000) { // 90% of 50k
    await sendAlert('Approaching read quota: ' + reads);
  }
  
  if (writes > 18000) { // 90% of 20k
    await sendAlert('Approaching write quota: ' + writes);
  }
}

// Run every hour
```

**Cost Monitoring Dashboard:**

```typescript
// Generate daily report
async function generateUsageReport() {
  const today = new Date().toISOString().split('T')[0];
  
  const report = {
    date: today,
    firestore: {
      reads: await getReadCount(today),
      writes: await getWriteCount(today),
      deletes: await getDeleteCount(today),
    },
    cloudflare: {
      requests: await getWorkerRequestCount(today),
    },
    admob: {
      impressions: await getAdImpressions(today),
      revenue: await getEstimatedRevenue(today),
    },
    users: {
      dau: await getDAU(today),
      mau: await getMAU(),
    },
  };
  
  // Store report
  await db.collection('usage_reports').doc(today).set(report);
  
  // Check if over budget
  if (report.firestore.reads > 50000 || report.firestore.writes > 20000) {
    await sendAlert('QUOTA EXCEEDED: ' + JSON.stringify(report));
  }
  
  return report;
}
```

---

## 11. Security & Anti-Fraud System

### 11.1 Multi-Layer Fraud Detection

**Layer 1: Device Fingerprinting**

```dart
import 'package:device_info_plus/device_info_plus.dart';

class DeviceFingerprint {
  static Future<String> generate() async {
    final deviceInfo = DeviceInfoPlugin();
    
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      
      return _hash([
        androidInfo.id,
        androidInfo.model,
        androidInfo.brand,
        androidInfo.device,
      ].join('|'));
    } else {
      final iosInfo = await deviceInfo.iosInfo;
      
      return _hash([
        iosInfo.identifierForVendor,
        iosInfo.model,
        iosInfo.name,
      ].join('|'));
    }
  }
  
  static String _hash(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }
}
```

**Layer 2: Behavioral Analysis**

```typescript
async function analyzeBehavior(userId) {
  const transactions = await db
    .collection('transactions')
    .where('userId', '==', userId)
    .orderBy('timestamp', 'desc')
    .limit(50)
    .get();
  
  const patterns = {
    avgTimeBetweenActions: calculateAvgTime(transactions),
    taskCompletionSpeed: calculateTaskSpeed(transactions),
    adWatchPatterns: analyzeAdPatterns(transactions),
    earningVelocity: calculateVelocity(transactions),
  };
  
  // Flag suspicious patterns
  const flags = [];
  
  if (patterns.avgTimeBetweenActions < 10) { // 10 seconds
    flags.push('too_fast');
  }
  
  if (patterns.taskCompletionSpeed < 5) { // 5 seconds per task
    flags.push('impossible_task_speed');
  }
  
  if (patterns.earningVelocity > 0.50) { // ₹0.50 per minute
    flags.push('high_velocity');
  }
  
  return { patterns, flags, suspicious: flags.length > 0 };
}
```

**Layer 3: Network Analysis**

```typescript
async function checkNetworkFraud(ipAddress, deviceId) {
  // Check how many accounts from this IP
  const ipAccounts = await db
    .collection('users')
    .where('security.ipAddress', '==', ipAddress)
    .count()
    .get();
  
  // Check device
  const deviceAccounts = await db
    .collection('users')
    .where('security.deviceId', '==', deviceId)
    .count()
    .get();
  
  const flags = [];
  
  if (ipAccounts.data().count > 5) {
    flags.push('ip_abuse');
  }
  
  if (deviceAccounts.data().count > 2) {
    flags.push('device_abuse');
  }
  
  // Check if IP is VPN/Proxy
  const ipInfo = await checkIP(ipAddress);
  if (ipInfo.isVPN || ipInfo.isProxy) {
    flags.push('vpn_detected');
  }
  
  return { flags, risk: flags.length > 0 ? 'high' : 'low' };
}
```

**Layer 4: ML-Based Detection (Future)**

```typescript
// Pseudocode for ML model
async function mlFraudDetection(userId) {
  const features = await extractFeatures(userId);
  
  // Features:
  // - Account age
  // - Tasks completed
  // - Avg time per task
  // - Withdrawal attempts
  // - Ad watch patterns
  // - Device changes
  // - IP changes
  // - Referral patterns
  
  const prediction = await fraudModel.predict(features);
  
  return {
    fraudProbability: prediction.probability,
    shouldBlock: prediction.probability > 0.8,
    shouldFlag: prediction.probability > 0.5,
  };
}
```

### 11.2 Automated Actions

```typescript
async function handleFraudDetection(userId, fraudData) {
  const { flags, risk } = fraudData;
  
  if (risk === 'high' || flags.includes('device_abuse')) {
    // Lock account immediately
    await db.collection('users').doc(userId).update({
      'security.accountLocked': true,
      'security.lockReason': flags.join(', '),
      'security.lockedAt': new Date(),
    });
    
    // Send notification to user
    await sendNotification(userId, 
      'Account Under Review',
      'Our team is reviewing your account. This may take 24-48 hours.'
    );
    
    // Alert admin
    await notifyAdmin('ACCOUNT LOCKED: ' + userId, fraudData);
    
    return { action: 'locked' };
  }
  
  if (risk === 'medium' || flags.length > 0) {
    // Flag for manual review
    await db.collection('users').doc(userId).update({
      'security.suspiciousActivity': true,
      'security.flags': flags,
    });
    
    // Add to review queue
    await db.collection('review_queue').add({
      userId,
      flags,
      timestamp: new Date(),
      status: 'pending',
    });
    
    return { action: 'flagged' };
  }
  
  return { action: 'none' };
}
```

### 11.3 Manual Review Dashboard

**Admin panel features:**

1. **Review Queue:**
   - List of flagged accounts
   - Fraud score
   - Activity timeline
   - Device/IP info

2. **Actions:**
   - Approve account
   - Lock account
   - Adjust earnings
   - Blacklist device/IP

3. **Analytics:**
   - Fraud rate over time
   - Most common fraud patterns
   - Blocked earnings

```typescript
// Admin API endpoint
async function handleManualReview(reviewId, action, adminId) {
  const review = await db.collection('review_queue').doc(reviewId).get();
  const { userId } = review.data();
  
  if (action === 'approve') {
    await db.collection('users').doc(userId).update({
      'security.suspiciousActivity': false,
      'security.flags': [],
      'security.reviewedBy': adminId,
      'security.reviewedAt': new Date(),
    });
    
    await db.collection('review_queue').doc(reviewId).update({
      status: 'approved',
      reviewedBy: adminId,
      reviewedAt: new Date(),
    });
  }
  
  if (action === 'block') {
    await db.collection('users').doc(userId).update({
      'security.accountLocked': true,
      'security.lockReason': 'Manual review - fraud confirmed',
      'security.reviewedBy': adminId,
      'security.reviewedAt': new Date(),
    });
    
    // Blacklist device and IP
    const user = await db.collection('users').doc(userId).get();
    await db.collection('blacklist').add({
      deviceId: user.data().security.deviceId,
      ipAddress: user.data().security.ipAddress,
      reason: 'Fraud confirmed',
      addedBy: adminId,
      addedAt: new Date(),
    });
  }
  
  return { success: true };
}
```

---

## 12. Testing Strategy

### 12.1 Unit Tests

**Test earning logic:**

```dart
void main() {
  group('Earning Logic Tests', () {
    test('Should credit ₹0.10 for task completion', () async {
      final user = MockUser(balance: 0.0);
      
      await EarningService.creditTaskEarning(user, 'task_1');
      
      expect(user.balance, 0.10);
    });
    
    test('Should reject earning above daily limit', () async {
      final user = MockUser(
        balance: 1.40,
        todayEarnings: 1.40,
      );
      
      expect(
        () => EarningService.creditTaskEarning(user, 'task_1'),
        throwsA(isA<DailyLimitException>()),
      );
    });
    
    test('Should enforce task cooldown', () async {
      final user = MockUser(lastTaskTime: DateTime.now());
      
      expect(
        () => EarningService.creditTaskEarning(user, 'task_1'),
        throwsA(isA<CooldownException>()),
      );
    });
  });
}
```

### 12.2 Integration Tests

**Test complete user flow:**

```dart
void main() {
  group('User Flow Integration Tests', () {
    testWidgets('Complete task and earn flow', (tester) async {
      // Launch app
      await tester.pumpWidget(MyApp());
      
      // Login
      await tester.enterText(find.byKey(Key('email')), 'test@test.com');
      await tester.enterText(find.byKey(Key('password')), 'password123');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();
      
      // Navigate to tasks
      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();
      
      // Start task
      await tester.tap(find.text('Start Task'));
      await tester.pumpAndSettle();
      
      // Watch ad (mocked)
      await MockAdManager.simulateAdCompletion();
      await tester.pumpAndSettle();
      
      // Complete task
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      
      // Verify earning
      expect(find.text('₹0.10'), findsOneWidget);
      expect(find.text('earned'), findsOneWidget);
    });
  });
}
```

### 12.3 Load Testing

**Simulate 10,000 concurrent users:**

```typescript
// Using Artillery or k6
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '2m', target: 1000 },  // Ramp up to 1000
    { duration: '5m', target: 10000 }, // Ramp up to 10000
    { duration: '10m', target: 10000 }, // Stay at 10000
    { duration: '2m', target: 0 },     // Ramp down
  ],
};

export default function () {
  // Simulate user session
  const userId = `user_${__VU}`;
  
  // Login
  let res = http.post('https://earnquest.workers.dev/api/login', {
    userId,
    token: 'test_token',
  });
  
  check(res, {
    'login successful': (r) => r.status === 200,
  });
  
  sleep(1);
  
  // Complete task
  res = http.post('https://earnquest.workers.dev/api/earn/task', {
    userId,
    taskId: 'task_1',
    completionProof: 'proof',
    deviceId: 'device_1',
  });
  
  check(res, {
    'task completed': (r) => r.status === 200,
    'earned ₹0.10': (r) => r.json('earned') === 0.10,
  });
  
  sleep(2);
  
  // Get leaderboard
  res = http.get('https://earnquest.workers.dev/api/leaderboard');
  
  check(res, {
    'leaderboard loaded': (r) => r.status === 200,
  });
  
  sleep(1);
}
```

---

## 13. Launch Checklist

### 13.1 Pre-Launch (Week -2)

**Technical:**
- [ ] All APIs tested and working
- [ ] Ad integration complete (test ads → live ads)
- [ ] Firebase security rules deployed
- [ ] Cloudflare Workers deployed
- [ ] Database indexes created
- [ ] Backup strategy implemented
- [ ] Monitoring/alerts configured

**Legal & Compliance:**
- [ ] Privacy Policy written and deployed
- [ ] Terms of Service written and deployed
- [ ] GDPR compliance (if applicable)
- [ ] AdMob policies reviewed
- [ ] Age restriction (18+) implemented

**Content:**
- [ ] App Store listing prepared
  - [ ] Screenshots (5-8)
  - [ ] App icon (512×512)
  - [ ] Feature graphic
  - [ ] Description optimized
- [ ] Onboarding copy finalized
- [ ] Error messages reviewed

### 13.2 Soft Launch (Week -1)

**Limited Release:**
- [ ] Deploy to 100 beta users
- [ ] Monitor for crashes
- [ ] Check ad fill rate
- [ ] Verify earning/payout flow
- [ ] Collect feedback

**Metrics to Track:**
- Daily crash rate < 1%
- Ad fill rate > 85%
- Withdrawal success rate > 95%
- Average session time > 10 min

### 13.3 Public Launch (Week 0)

**Day 1:**
- [ ] Release to Google Play Store
- [ ] Monitor real-time analytics
- [ ] Watch server load
- [ ] Track quota usage
- [ ] Respond to reviews

**Marketing:**
- [ ] Social media posts
- [ ] Email list notification
- [ ] Referral campaign launch
- [ ] Influencer outreach (optional)

### 13.4 Post-Launch (Week +1)

**Monitoring:**
- [ ] Daily usage reports
- [ ] Fraud detection review
- [ ] Withdrawal queue processing
- [ ] User support responses
- [ ] Bug fixes deployment

**Optimization:**
- [ ] Ad placement tweaks based on data
- [ ] Earning balance adjustments
- [ ] UI/UX improvements
- [ ] Performance optimization

---

## 14. Growth & Retention Strategy

### 14.1 Engagement Loops

**Daily Loop:**
```
Morning Notification (9 AM)
    ↓
User Opens App
    ↓
Sees Streak Badge
    ↓
Completes 1-2 Tasks
    ↓
Plays 1-2 Games
    ↓
Watches Bonus Ads
    ↓
Checks Leaderboard
    ↓
Feels Progress
    ↓
Returns Tomorrow (Streak Motivation)
```

**Weekly Loop:**
```
Monday: Weekly goal set (Earn ₹7 this week)
Tuesday-Thursday: Daily progress
Friday: "Almost there!" notification
Saturday: Achievement unlocked
Sunday: Week recap + next week teaser
```

**Monthly Loop:**
```
Week 1-2: Build earnings
Week 3: Reach withdrawal threshold (₹50)
Week 4: Process withdrawal
Month end: Success story + referral push
```

### 14.2 Retention Tactics

**Day 1 Retention (Target: 40%):**
- Immediate ₹0.50 signup bonus (if referred)
- Quick first earning (₹0.10 in <2 min)
- Achievement: "First Earning" badge
- Push notification next day

**Day 7 Retention (Target: 25%):**
- Streak system (7-day milestone = ₹0.50 bonus)
- Leaderboard rank improvement
- Weekly earning summary email
- "You're 70% to withdrawal!" progress message

**Day 30 Retention (Target: 12%):**
- First withdrawal success
- Referral earnings kicking in
- Habit formed (daily routine)
- New game/task unlocks

### 14.3 Viral Growth

**Referral Mechanics:**
- Easy share (1-tap WhatsApp)
- Clear incentive (₹2 per referral)
- Progress tracking (referee at ₹6/₹10)
- Social proof ("3 friends earning with you")

**Share Triggers:**
- After first withdrawal: "I just withdrew ₹50!"
- Leaderboard rank improvement: "I'm #15!"
- Big spin win: "I won ₹1 on spin!"
- Streak milestone: "7-day streak!"

---

## 15. Future Roadmap

### Version 1.1 (Month 2-3)
- [ ] More game types (2048, Word Search)
- [ ] Daily challenges with bonus rewards
- [ ] Achievement system
- [ ] Profile customization

### Version 1.2 (Month 4-6)
- [ ] Team/squad feature (group earnings)
- [ ] Tournaments with prizes
- [ ] Premium tasks (higher payout)
- [ ] Offerwalls integration

### Version 2.0 (Month 7-12)
- [ ] iOS version
- [ ] In-app purchases (coins)
- [ ] Cryptocurrency withdrawal option
- [ ] International expansion

---

## 16. Success Metrics Summary

### Launch Goals (Month 1)
| Metric | Target |
|--------|--------|
| Downloads | 1,000 |
| DAU | 300 |
| Retention D7 | 25% |
| Avg Revenue/User | ₹10 |
| Withdrawal Rate | 20% |

### Growth Goals (Month 6)
| Metric | Target |
|--------|--------|
| Total Users | 10,000 |
| DAU | 2,500 |
| Monthly Revenue | ₹25,000 |
| Monthly Payouts | ₹6,000 |
| Profit | ₹19,000 |

### KPIs to Monitor Daily
- DAU/MAU ratio
- Ad fill rate
- Average earnings per user
- Withdrawal completion rate
- Fraud rate
- App crash rate
- API response time

---

## 17. Appendix

### 17.1 Glossary

- **DAU**: Daily Active Users
- **MAU**: Monthly Active Users
- **ARPU**: Average Revenue Per User
- **eCPM**: Effective Cost Per Mille (1000 impressions)
- **Fill Rate**: % of ad requests successfully filled
- **Churn**: % of users who stop using the app

### 17.2 Contact & Support

**Support Email:** support@earnquest.app  
**Business Inquiries:** business@earnquest.app  
**Report Fraud:** fraud@earnquest.app  

**Support Hours:** 9 AM - 9 PM IST, 7 days/week  
**Response Time:** <24 hours

### 17.3 Legal Documents

**Privacy Policy URL:** `earnquest.app/privacy`  
**Terms of Service URL:** `earnquest.app/terms`  
**Refund Policy:** No refunds (earnings-based, not purchases)

---

## Document Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | Nov 2025 | Initial PRD | Product Team |

---

**END OF PRD**

**Next Steps:**
1. Review with engineering team
2. Create technical design doc
3. Set up development environment
4. Sprint planning (2-week sprints)
5. Begin development

**Estimated Timeline:**
- Sprint 1-2: Core backend + auth (2 weeks)
- Sprint 3-4: Home screen + tasks (2 weeks)
- Sprint 5-6: Games + ads integration (2 weeks)
- Sprint 7-8: Withdrawal + leaderboard (2 weeks)
- Sprint 9-10: Testing + polish (2 weeks)
- Sprint 11-12: Beta launch + fixes (2 weeks)

**Total: 12 weeks (3 months) to public launch**

---

## 18. Critical Improvements & Missing Features

### 18.1 Push Notification Strategy (FCM Required)

**Why Critical:** Local notifications aren't enough for re-engagement.

**Firebase Cloud Messaging Setup:**

```dart
// Add to pubspec.yaml
firebase_messaging: ^14.6.9

// Notification handler
class PushNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: