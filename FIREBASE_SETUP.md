# Firebase Setup Guide for EarnQuest

This guide covers the complete Firebase setup for the EarnQuest app.

## 1. Firebase Project Creation

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **Create a new project** or **Add project**
3. Enter project name: `EarnQuest`
4. Accept the terms and click **Create project**
5. Wait for project creation to complete

## 2. Firebase Authentication Setup

### Enable Authentication Methods

1. Go to **Authentication** → **Sign-in method**
2. Enable these sign-in providers:
   - **Email/Password**
     - Click enable
     - Choose "Email/password" (without phone)
     - Save
   - **Google**
     - Click enable
     - Add your app name and support email
     - Download OAuth 2.0 Client ID from Google Cloud Console
     - Save

### Create Test Users (Optional)

1. Go to **Authentication** → **Users**
2. Add test users for testing authentication

## 3. Firestore Database Setup

### Create Database

1. Go to **Firestore Database**
2. Click **Create database**
3. Select region: **asia-south1** (Mumbai - closest to India)
4. Choose security rules:
   - Start in **Test Mode** (for development)
   - For production, update rules in Section 7

### Create Collections & Indexes

#### Collection: `users`
```json
// Document ID: {userId}
{
  "userId": "string",
  "email": "string",
  "displayName": "string",
  "profilePictureUrl": "string (optional)",
  "availableBalance": "double",
  "totalEarned": "double",
  "totalWithdrawn": "double",
  "currentStreak": "integer",
  "longestStreak": "integer",
  "lastTaskCompletion": "timestamp",
  "lastGameCompletion": "timestamp",
  "tasksCompletedToday": "integer",
  "gamesPlayedToday": "integer",
  "adsWatchedToday": "integer",
  "dailySpins": "integer",
  "lastSpinTime": "timestamp",
  "referralCode": "string",
  "referralCount": "integer",
  "referredBy": "string (optional)",
  "accountCreatedAt": "timestamp",
  "lastLoginAt": "timestamp",
  "isAccountLocked": "boolean",
  "lockReason": "string",
  "kycVerified": "boolean",
  "upiId": "string (optional)"
}
```

#### Collection: `transactions`
```json
// Document ID: {transactionId}
{
  "transactionId": "string",
  "userId": "string",
  "type": "string", // "task", "game", "ad", "spin", "referral", "bonus"
  "amount": "double",
  "description": "string",
  "source": "string", // "task_id", "game_id", etc.
  "timestamp": "timestamp",
  "status": "string", // "completed", "pending"
  "deviceId": "string",
  "ipAddress": "string"
}
```

#### Collection: `withdrawals`
```json
// Document ID: {withdrawalId}
{
  "withdrawalId": "string",
  "userId": "string",
  "amount": "double",
  "upiId": "string",
  "status": "string", // "pending", "processing", "completed", "failed"
  "createdAt": "timestamp",
  "processedAt": "timestamp (optional)",
  "transactionRef": "string (optional)",
  "failureReason": "string (optional)"
}
```

#### Collection: `leaderboard`
```json
// Document ID: {userId}
{
  "userId": "string",
  "displayName": "string",
  "totalEarnings": "double",
  "rank": "integer",
  "lastUpdated": "timestamp",
  "profilePicUrl": "string (optional)"
}
```

#### Collection: `daily_spins`
```json
// Document ID: {userId}
{
  "userId": "string",
  "date": "date",
  "spinsUsed": "integer",
  "lastSpinTime": "timestamp",
  "totalSpins": "integer"
}
```

#### Collection: `tasks`
```json
// Document ID: {taskId}
{
  "taskId": "string",
  "title": "string",
  "description": "string",
  "type": "string", // "survey", "social_share", "app_rating"
  "reward": "double",
  "timeRequired": "integer",
  "isActive": "boolean",
  "createdAt": "timestamp",
  "endDate": "timestamp (optional)"
}
```

## 4. Firestore Security Rules

Replace the default security rules with these rules:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // Users Collection
    match /users/{userId} {
      allow read: if request.auth.uid == userId;
      allow create: if request.auth.uid == userId && 
                       request.resource.data.email == request.auth.token.email;
      allow update: if request.auth.uid == userId &&
                       request.resource.data.email == resource.data.email;
      allow delete: if request.auth.uid == userId;
    }

    // Transactions Collection (Read-only for users)
    match /transactions/{document=**} {
      allow read: if request.auth.uid == resource.data.userId;
      allow create: if request.auth != null;
      allow update, delete: if false;
    }

    // Withdrawals Collection
    match /withdrawals/{withdrawalId} {
      allow read: if request.auth.uid == resource.data.userId;
      allow create: if request.auth != null && 
                       request.auth.uid == request.resource.data.userId;
      allow update, delete: if false;
    }

    // Leaderboard Collection (Public read)
    match /leaderboard/{userId} {
      allow read: if true;
      allow create, update, delete: if false;
    }

    // Daily Spins Collection
    match /daily_spins/{userId} {
      allow read: if request.auth.uid == userId;
      allow create, update: if request.auth.uid == userId;
      allow delete: if false;
    }

    // Tasks Collection (Public read)
    match /tasks/{taskId} {
      allow read: if true;
      allow create, update, delete: if false;
    }

    // Admin Panel (Optional)
    match /admin/{document=**} {
      allow read, write: if request.auth.token.email in ['admin@earnquest.app'];
    }
  }
}
```

## 5. Firebase Real-Time Database (Optional)

If you want to use Real-time Database for leaderboard updates:

1. Go to **Realtime Database**
2. Create database in region **asia-south1**
3. Use these rules:

```json
{
  "rules": {
    "leaderboard": {
      ".read": true,
      ".write": false
    },
    "users": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid"
      }
    }
  }
}
```

## 6. Firebase Analytics Setup

Analytics is automatically enabled. To add custom events:

1. Go to **Analytics** → **Events**
2. Create custom events for tracking:
   - `task_completed`
   - `game_played`
   - `ad_watched`
   - `spin_used`
   - `withdrawal_requested`
   - `level_reached`

## 7. Firebase Functions (Scheduled Tasks)

Create Cloud Functions for:
- Daily leaderboard reset
- Automatic withdrawal processing
- Streak reset at midnight
- Daily bonus distribution

Example: `functions/index.js`

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Daily reset at midnight IST
exports.dailyReset = functions.pubsub
  .schedule('0 0 * * *')
  .timeZone('Asia/Kolkata')
  .onRun(async (context) => {
    const batch = admin.firestore().batch();
    const users = await admin.firestore().collection('users').get();
    
    users.forEach((doc) => {
      batch.update(doc.ref, {
        tasksCompletedToday: 0,
        gamesPlayedToday: 0,
        adsWatchedToday: 0,
        dailySpins: 0,
        lastTaskCompletion: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
    
    return batch.commit();
  });

// Process pending withdrawals
exports.processWithdrawals = functions.pubsub
  .schedule('0 */6 * * *') // Every 6 hours
  .timeZone('Asia/Kolkata')
  .onRun(async (context) => {
    const pending = await admin.firestore()
      .collection('withdrawals')
      .where('status', '==', 'pending')
      .where('createdAt', '<', new Date(Date.now() - 24 * 60 * 60 * 1000))
      .get();
    
    // Process each withdrawal
    // Update status to 'processing'
    
    return null;
  });
```

## 8. Flutter Firebase Integration

### Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### Configure Firebase

```bash
flutterfire configure --project=earnquest
```

This will automatically configure Firebase for your app.

### Firebase Initialization in App

The `main.dart` should initialize Firebase:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Auto-generated

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

## 9. Google Cloud Console Configuration

### Enable Required APIs

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Enable these APIs:
   - Firestore API
   - Firebase Authentication API
   - Firebase Real-time Database API
   - Firebase Cloud Functions API
   - Firebase Cloud Storage API

### Service Account Setup

1. Go to **Service Accounts**
2. Generate a new private key
3. Use this for backend/Cloudflare Workers

## 10. Android Configuration

### Add SHA-1 Fingerprint

1. Go to **Project Settings** → **Your apps**
2. Click Android app
3. Add SHA-1 fingerprint:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

### Update AndroidManifest.xml

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.READ_PHONE_STATE" />
    
    <application>
        <!-- Firebase Configuration -->
        <meta-data
            android:name="com.google.android.gms.version"
            android:value="@integer/google_play_services_version" />
    </application>
</manifest>
```

## 11. iOS Configuration

### Update Info.plist

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
    </array>
  </dict>
</array>

<key>FirebaseScreenReportingEnabled</key>
<true/>
```

## 12. Testing Firebase Locally

### Install Firebase Emulator

```bash
npm install -g firebase-tools
firebase emulators:start
```

Then connect Flutter to emulator in development:

```dart
if (kDebugMode) {
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
}
```

## 13. Monitoring & Debugging

### Monitor Firestore Usage

1. Go to **Firestore** → **Usage**
2. Monitor:
   - Daily read count
   - Daily write count
   - Daily delete count
   - Storage usage

### Set Up Alerts

1. Go to **Monitoring** → **Alerting Policies**
2. Create alerts for:
   - High read/write operations
   - Quota exceeded
   - Authentication failures

### Enable Debug Logging

```dart
// In development
FirebaseAuth.instance.userChanges().listen((user) {
  debugPrint('User: $user');
});

FirebaseFirestore.instance.collection('users').snapshots().listen((snapshot) {
  debugPrint('Users snapshot: ${snapshot.docs.length}');
});
```

## 14. Production Checklist

- [ ] Disable Test Mode for Firestore
- [ ] Apply restrictive security rules
- [ ] Enable backup & disaster recovery
- [ ] Set up monitoring & alerts
- [ ] Configure database indexing
- [ ] Enable audit logging
- [ ] Set up Cloud Functions for automation
- [ ] Configure Firebase App Check
- [ ] Set up error reporting
- [ ] Enable performance monitoring

## 15. Useful Links

- [Firebase Console](https://console.firebase.google.com/)
- [Google Cloud Console](https://console.cloud.google.com/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Docs](https://firebase.flutter.dev/)
- [Firestore Best Practices](https://firebase.google.com/docs/firestore/best-practices)

---

**Created:** November 22, 2025
**Version:** 1.0
