# Cloudflare Workers Backend Setup

This guide will help you set up the Cloudflare Workers backend for EarnQuest.

## Prerequisites

- Cloudflare account (free tier is sufficient)
- Node.js 16+ installed
- `wrangler` CLI tool

## Step 1: Install Wrangler

```bash
npm install -g @cloudflare/wrangler
# or
yarn global add @cloudflare/wrangler
```

## Step 2: Create Wrangler Project

```bash
wrangler init earnquest-worker
cd earnquest-worker
```

## Step 3: Configure wrangler.toml

Replace the content of `wrangler.toml` with:

```toml
name = "earnquest-worker"
main = "src/index.ts"
compatibility_date = "2024-01-01"

[env.production]
route = "earnquest.workers.dev"
zone_id = "your_zone_id"

[build]
command = "npm install && npm run build"
cwd = "./"

[build.upload]
format = "modules"

[[triggers.crons]]
cron = "0 0 * * *"
```

## Step 4: Create Environment Variables

Create a `.env` file (never commit this):

```env
FIREBASE_API_KEY=your_firebase_api_key
FIREBASE_PROJECT_ID=your_project_id
DATABASE_URL=your_firebase_url
WEBHOOK_SECRET=your_webhook_secret
```

Or use Wrangler secrets:

```bash
wrangler secret put FIREBASE_API_KEY
wrangler secret put FIREBASE_PROJECT_ID
wrangler secret put DATABASE_URL
wrangler secret put WEBHOOK_SECRET
```

## Step 5: Upload Worker

```bash
wrangler publish
```

Your worker will be available at:  
`https://earnquest.workers.dev`

## Step 6: Test Endpoints

```bash
# Test task earning endpoint
curl -X POST https://earnquest.workers.dev/api/earn/task \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "test_user",
    "taskId": "survey_1",
    "deviceId": "device_123"
  }'

# Test game earning endpoint
curl -X POST https://earnquest.workers.dev/api/earn/game \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "test_user",
    "gameId": "tictactoe",
    "won": true,
    "deviceId": "device_123"
  }'
```

## API Endpoints

### 1. Task Earning
- **Endpoint:** `POST /api/earn/task`
- **Purpose:** Record task completion and award earnings
- **Rate Limit:** 1 per minute per user

```json
{
  "userId": "user_id",
  "taskId": "task_id",
  "deviceId": "device_id"
}
```

Response:
```json
{
  "success": true,
  "earned": 0.10,
  "newBalance": 1.50,
  "message": "Task completed successfully"
}
```

### 2. Game Earning
- **Endpoint:** `POST /api/earn/game`
- **Purpose:** Record game result and award earnings (if won)
- **Rate Limit:** 1 per 30 minutes per user (cooldown)

```json
{
  "userId": "user_id",
  "gameId": "game_id",
  "won": true,
  "score": 45,
  "deviceId": "device_id"
}
```

Response:
```json
{
  "success": true,
  "earned": 0.08,
  "newBalance": 1.58,
  "cooldownMinutes": 30
}
```

### 3. Ad Earning
- **Endpoint:** `POST /api/earn/ad`
- **Purpose:** Record ad view and award earnings
- **Rate Limit:** 15 per day per user

```json
{
  "userId": "user_id",
  "adType": "rewarded",
  "deviceId": "device_id"
}
```

Response:
```json
{
  "success": true,
  "earned": 0.03,
  "newBalance": 1.61,
  "adsRemainingToday": 12
}
```

### 4. Spin Wheel
- **Endpoint:** `POST /api/spin`
- **Purpose:** Execute daily spin and award random reward
- **Rate Limit:** 1 per day per user

```json
{
  "userId": "user_id",
  "deviceId": "device_id"
}
```

Response:
```json
{
  "success": true,
  "reward": 0.50,
  "newBalance": 2.11,
  "nextSpinAvailableAt": "2025-11-23T00:00:00Z"
}
```

### 5. Get Leaderboard
- **Endpoint:** `GET /api/leaderboard?limit=50`
- **Purpose:** Fetch top earners
- **Cache:** 5 minutes

Response:
```json
{
  "leaderboard": [
    {
      "rank": 1,
      "userId": "user_1",
      "displayName": "Rajesh K.",
      "totalEarnings": 250.50
    },
    ...
  ],
  "lastUpdated": "2025-11-22T10:30:00Z"
}
```

### 6. Withdrawal Request
- **Endpoint:** `POST /api/withdrawal/request`
- **Purpose:** Create withdrawal request
- **Validation:** Minimum balance ₹50, account age 7 days

```json
{
  "userId": "user_id",
  "amount": 100.00,
  "upiId": "user@bank",
  "deviceId": "device_id"
}
```

Response:
```json
{
  "success": true,
  "withdrawalId": "wd_123",
  "status": "pending",
  "message": "Withdrawal will be processed in 24-48 hours"
}
```

### 7. User Stats
- **Endpoint:** `GET /api/user/stats?userId=user_id`
- **Purpose:** Get user daily/monthly statistics
- **Cache:** 30 seconds

Response:
```json
{
  "earnings": {
    "today": 0.50,
    "thisMonth": 12.50,
    "allTime": 250.50
  },
  "limits": {
    "remainingToday": 1.00,
    "tasksRemaining": 2,
    "gamesRemaining": 5,
    "adsRemaining": 10
  },
  "streak": {
    "current": 3,
    "longest": 15
  },
  "nextResetTime": "2025-11-23T00:00:00Z"
}
```

## Error Codes

| Code | Message |
|------|---------|
| 400 | Bad request / Invalid parameters |
| 401 | Unauthorized / Invalid token |
| 429 | Rate limit exceeded |
| 500 | Internal server error |
| 503 | Service unavailable |

## Rate Limiting

```
Per IP: 100 requests/minute
Per User: 50 requests/minute
```

## Security Considerations

1. **Device Fingerprinting:** Prevent multiple accounts per device
2. **IP Tracking:** Monitor suspicious activity
3. **Timestamps:** Validate request timing
4. **Fraud Detection:** Flag impossible completion times
5. **Webhook Signing:** Validate payment webhooks

## Deployment

### Development
```bash
wrangler dev
```

### Production
```bash
wrangler publish --env production
```

## Monitoring

View logs:
```bash
wrangler tail
```

## Cost Estimate

- **Free Tier:** 100,000 requests/day
- **Target Load:** ~50,000 requests/day
- **Cost:** Free (within limits)

---

**Next Steps:**
1. Create the worker code in `src/index.ts`
2. Set up Firestore integration
3. Deploy and test all endpoints
4. Set up monitoring and alerts
