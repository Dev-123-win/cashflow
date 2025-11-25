# Authentication Race Condition Fix

## Problem Identified

**Issue:** User creates account and logs in successfully (user exists in Firebase Auth), but after redirect to home screen, the app shows "Please sign in to continue".

**Root Cause:** Race condition between user authentication and user data initialization.

### The Flow:
1. User logs in → Firebase Auth succeeds
2. App redirects to `MainNavigationScreen` → shows `HomeScreen`
3. `HomeScreen` builds and checks `userProvider.user.userId.isEmpty`
4. At this point, user initialization hasn't completed yet
5. Result: Shows "Please sign in to continue" even though user is authenticated

### Why This Happens:
- **main.dart** (lines 178-185): Initializes user using `addPostFrameCallback` (async)
- **home_screen.dart** (lines 41-48): Also tries to initialize user using `Future.microtask` (async)
- Both are asynchronous, so `HomeScreen` renders before user data loads

---

## Solution

### Step 1: Fix `lib/main.dart`

Replace the `AuthenticationWrapper` build method (lines 144-193) with this:

```dart
  @override
  Widget build(BuildContext context) {
    // Show splash screen first
    if (_showSplash) {
      return const SplashScreen();
    }

    return StreamBuilder(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '💰',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineLarge?.copyWith(fontSize: 64.0),
                  ),
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }

        // User is logged in
        if (snapshot.hasData && snapshot.data != null) {
          // Use Consumer to ensure UserProvider is initialized before showing home
          return Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              // Initialize user if not already initialized
              if (userProvider.user.userId.isEmpty && !userProvider.isLoading) {
                // Initialize user synchronously
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    userProvider.initializeUser(snapshot.data!.uid);
                  }
                });
                
                // Show loading while initializing
                return Scaffold(
                  backgroundColor: AppTheme.backgroundColor,
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '💰',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineLarge?.copyWith(fontSize: 64.0),
                        ),
                        const SizedBox(height: 16),
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        const Text('Loading your profile...'),
                      ],
                    ),
                  ),
                );
              }
              
              // User is initialized, show main screen
              return const MainNavigationScreen();
            },
          );
        }

        // User is not logged in - show auth screen
        return const AuthenticationScreen();
      },
    );
  }
```

### Step 2: Fix `lib/screens/home/home_screen.dart`

Remove the duplicate user initialization from `HomeScreen` since it's now handled in `main.dart`.

**Remove these lines (lines 41-49):**
```dart
  void _loadData() {
    // Initialize user from Firebase
    Future.microtask(() {
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null && mounted) {
        context.read<UserProvider>().initializeUser(user.uid);
      }
    });
  }
```

**And remove the call to `_loadData()` from `initState` (line 38):**
```dart
  @override
  void initState() {
    super.initState();
    _adService = AdService();
    // _loadData(); // REMOVE THIS LINE
  }
```

---

## What This Fix Does

### Before (Broken):
1. User logs in
2. Redirects to `MainNavigationScreen` immediately
3. `HomeScreen` renders before user data loads
4. Shows "Please sign in to continue"

### After (Fixed):
1. User logs in
2. `Consumer<UserProvider>` checks if user is initialized
3. If not initialized: Shows loading screen while initializing
4. Once initialized: Shows `MainNavigationScreen`
5. `HomeScreen` now has user data available

---

## Key Changes

1. **Wrapped navigation in `Consumer<UserProvider>`**: This ensures we wait for user data before showing the home screen

2. **Added loading state**: Shows "Loading your profile..." while user data is being fetched

3. **Removed duplicate initialization**: `HomeScreen` no longer tries to initialize user (prevents race condition)

4. **Single source of truth**: Only `main.dart` handles user initialization

---

## Testing

After applying the fix:

1. **Create a new account**:
   ```
   - Sign up with new email
   - Should see "Loading your profile..." briefly
   - Should land on home screen with user data loaded
   ```

2. **Login with existing account**:
   ```
   - Login with existing credentials
   - Should see "Loading your profile..." briefly
   - Should land on home screen with user data loaded
   ```

3. **App restart (persistent session)**:
   ```
   - Close and reopen app
   - Should automatically login
   - Should see user data on home screen
   ```

---

## Alternative Quick Fix (If Above Doesn't Work)

If the above solution is too complex, here's a simpler fix:

### In `lib/providers/user_provider.dart`, make initialization synchronous:

Change the `initializeUser` method to set loading state properly:

```dart
Future<void> initializeUser(String userId) async {
  try {
    _isLoading = true;
    _user = User.empty(); // Clear old data
    notifyListeners(); // Notify immediately

    // Listen to real-time user updates from Firestore
    _userSubscription = _firestoreService
        .getUserStream(userId)
        .listen(
          (user) {
            if (user != null) {
              _user = user;
              _isAuthenticated = true;
              _error = null;
              _isLoading = false; // Set loading false when data arrives
              notifyListeners();
            }
          },
          onError: (error) {
            _error = error.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  } catch (e) {
    _error = e.toString();
    _isLoading = false;
    notifyListeners();
  }
}
```

This ensures `isLoading` is properly managed and the UI waits for data.

---

## Summary

**Problem**: Race condition between auth and user data initialization  
**Solution**: Use `Consumer<UserProvider>` to wait for user data before showing home screen  
**Result**: User data is always available when `HomeScreen` renders  

Apply the fixes above and test the authentication flow!
