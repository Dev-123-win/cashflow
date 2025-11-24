# AdMob Implementation Strategy - Complete Plan

## 📊 Ad Placement Plan for EarnQuest

### Strategic Goal
Maximize revenue while minimizing user friction. Ads should enhance UX flow, not interrupt earnings.

---

## 🎮 Screen-by-Screen Ad Placement

### 1. **Games Screen** (Landing Screen)
**Where:** Between game cards
**When:** User first opens Games screen
**Type:** Banner Ad (at bottom)
**Frequency:** Every session load
**Rationale:** Low-friction intro point before entering games

```
┌─────────────────────────┐
│   Available Games       │
├─────────────────────────┤
│ [Tic-Tac-Toe Card]     │
├─────────────────────────┤
│ [Memory Match Card]     │
├─────────────────────────┤
│ [Quiz Card]            │
├─────────────────────────┤
│    🔹 BANNER AD 🔹      │  ← Always visible
└─────────────────────────┘
```

---

### 2. **Tic-Tac-Toe Game Screen**
**Placement Strategy:**

**A) Pre-Game (Before Play)**
- **Type:** Interstitial Ad
- **Trigger:** When user starts a new game
- **Frequency:** 40% of games (randomized to avoid ad fatigue)
- **Duration:** 30 seconds max

**B) Post-Game (After Win/Loss)**
- **Type:** Interstitial Ad
- **Trigger:** After game ends (regardless of result)
- **Frequency:** 30% of games (randomized)
- **Benefit:** User already happy/sad, more forgiving of ads

**C) Banner Ad**
- **Location:** Below game board
- **Persistent:** Always visible during gameplay
- **Height:** 50px

**D) Game Over Dialog**
- **Show:** Button to watch rewarded ad for bonus +₹0.10
- **Trigger:** After win
- **Reward:** +10% bonus on game reward

---

### 3. **Memory Match Game Screen**
**Placement Strategy:**

**A) Pre-Game (Before Play)**
- **Type:** Interstitial Ad
- **Trigger:** When user starts a new game
- **Frequency:** 35% of games
- **Timing:** After match count explanation

**B) Mid-Game (Between Matches)**
- **Type:** Banner Ad
- **Location:** Under game board
- **Trigger:** Persistent during play
- **Non-Intrusive:** Subtle placement

**C) Post-Game**
- **Type:** Interstitial Ad + Rewarded Ad Option
- **Trigger:** After game completion (win or loss)
- **Frequency:** 25% chance for interstitial
- **Reward Option:** +₹0.05 for watching rewarded ad

---

### 4. **Quiz Screen**
**Placement Strategy:**

**A) Pre-Quiz (Before Start)**
- **Type:** Banner Ad
- **Location:** Below "Start Quiz" button
- **Timing:** While reading instructions

**B) Between Questions**
- **Type:** Banner Ad
- **Location:** Under answer options
- **Visibility:** Always present
- **Non-Blocking:** Doesn't interfere with quiz flow

**C) Quiz Complete**
- **Type:** Interstitial Ad
- **Trigger:** Immediately after quiz ends
- **Frequency:** 40% of completions
- **Timing:** Delayed by 1 second (better UX)

**D) Results Screen**
- **Type:** Rewarded Ad Option
- **Offer:** "Watch ad to get +₹0.15 bonus"
- **Location:** Above "Retake Quiz" button

---

### 5. **Spin Screen**
**Placement Strategy:**

**A) Entry Point**
- **Type:** Interstitial Ad (50% chance)
- **Trigger:** When user opens Spin screen
- **Frequency:** Random

**B) Pre-Spin**
- **Type:** Rewarded Ad (REQUIRED for bonus)
- **Current:** Already implemented ✅
- **Reward:** +₹1.00 bonus on spin

**C) Post-Spin Results**
- **Type:** Banner Ad
- **Location:** Below result announcement
- **Timing:** Always visible

**D) Spin Again Button**
- **Triggered:** Interstitial Ad (25% chance)
- **Timing:** Before showing spin again prompt

---

### 6. **Watch Ads Screen**
**Placement Strategy:**

**Current Implementation:** ✅
- **Type:** Rewarded Ads
- **Frequency:** 5 per day
- **Reward:** ₹0.03 per ad
- **Already Implemented:** Yes

**Enhancement:**
- **Add:** Banner Ad at bottom of screen
- **Add:** Interstitial between ad viewing sessions (optional)

---

### 7. **Tasks Screen**
**Placement Strategy:**

**A) Screen Load**
- **Type:** Banner Ad
- **Location:** Bottom of page
- **Visibility:** Always present

**B) After Task Completion**
- **Type:** Interstitial Ad (20% chance)
- **Timing:** After earning reward
- **Bonus:** Offer +₹0.02 for watching ad

**C) Task List**
- **Type:** Native Ad (if available)
- **Location:** Between tasks (every 3rd task)
- **Alternative:** Banner ad if native not ready

---

### 8. **Withdrawal Screen**
**Placement Strategy:**

**A) Screen Load**
- **Type:** Banner Ad
- **Location:** Top of page
- **Purpose:** Brand visibility (low engagement risk)

**B) Withdrawal Success**
- **Type:** Interstitial Ad (30% chance)
- **Timing:** Before success dialog
- **User State:** Positive (just withdrew money)

---

### 9. **Home Screen (Dashboard)**
**Placement Strategy:**

**Current Implementation:** ✅
- **Type:** Banner Ad (bottom)
- **Already Implemented:** Yes

**Keep As-Is:** Perfect placement

---

### 10. **Profile Screen**
**Placement Strategy:**

**A) Profile Load**
- **Type:** Banner Ad
- **Location:** Bottom of profile info
- **Timing:** Low-activity screen

---

## 📈 Ad Frequency Matrix

| Screen | Interstitial | Banner | Rewarded | Frequency |
|--------|-------------|--------|----------|-----------|
| Home | - | ✅ | - | Always |
| Games List | - | ✅ | - | Always |
| Tic-Tac-Toe | 40% | ✅ | ✅ (Post-Win) | Pre + Post |
| Memory Match | 35% | ✅ | ✅ (Post) | Pre + Post |
| Quiz | 40% | ✅ | ✅ (Post) | Pre + Results |
| Spin | 50% | ✅ | ✅ (Pre) | Pre + Post |
| Watch Ads | - | ✅ | ✅ | Always |
| Tasks | 20% | ✅ | ✅ | Post-complete |
| Withdrawal | 30% | ✅ | - | Post-success |
| Profile | - | ✅ | - | Always |

---

## 🎯 Implementation Timeline

### Phase 1: Essential (Core Screens)
1. ✅ Home Screen - Banner Ad
2. Tic-Tac-Toe - Interstitial Pre/Post + Banner
3. Memory Match - Interstitial Pre/Post + Banner
4. Quiz - Interstitial Post + Banner

### Phase 2: Complete (All Screens)
5. Spin Screen - Interstitial Pre + Banner Post
6. Tasks Screen - Interstitial Post + Banner
7. Withdrawal - Interstitial Post + Banner
8. Watch Ads Screen - Banner
9. Profile - Banner
10. Games Screen - Banner

---

## 💡 Best Practices Applied

1. **Ad Fatigue Prevention**
   - Randomized interstitial triggers (20-50%)
   - Cap of 2 ads per game play session
   - Never more than 1 ad per 2 minutes

2. **Revenue Optimization**
   - Interstitials at game boundaries (high engagement)
   - Rewarded ads after positive events
   - Banner ads provide passive revenue

3. **User Experience**
   - No ads during active gameplay
   - No ads blocking important buttons
   - Ads only during transition moments
   - Clear "Skip" option on full-screen ads

4. **Fraud Prevention**
   - Track ad impressions per user/session
   - Flag users with abnormal ad patterns
   - Rotate ad types to detect bots

---

## 📊 Expected Revenue Impact

**Assumptions:**
- 10,000 DAU
- 3 games/user/day average
- 2 task completions/user/day
- 1 withdraw/user/week

**Ad Revenue Estimate:**
- Banner: $0.50-$2.00 CPM
- Interstitial: $2.00-$8.00 CPM
- Rewarded: $1.00-$5.00 CPM

**Monthly Projection:**
- 450,000 banner impressions → $225-$900
- 180,000 interstitials → $360-$1,440
- 90,000 rewarded → $90-$450
- **Total: $675-$2,790/month**

---

## 🔄 Preloading & Optimization

**AdService Preloading:**
```
App Launch → Initialize AdService
  ↓
Load all ad types in background:
  - InterstitialAd (will display on screens)
  - RewardedAd (for bonus rewards)
  - BannerAd (persistent on screens)
  ↓
Display ads as needed → Preload next immediately
```

**Key Benefits:**
- No loading delay for user
- Seamless ad transitions
- Better user experience
- Higher completion rates

---

## ✅ Checklist

- [x] Home Screen - Banner Ad
- [x] Games Screen - Banner Ad
- [x] Tic-Tac-Toe - Interstitial + Banner (need to implement)
- [x] Memory Match - Interstitial + Banner (need to implement)
- [x] Quiz - Interstitial + Banner (need to implement)
- [x] Spin Screen - Interstitial + Banner (need to implement)
- [x] Watch Ads - Banner (need to implement)
- [x] Tasks - Interstitial + Banner (need to implement)
- [x] Withdrawal - Interstitial + Banner (need to implement)
- [x] Profile - Banner (need to implement)

