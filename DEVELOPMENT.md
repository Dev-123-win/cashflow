# EarnQuest Development Guide

A comprehensive guide for developers working on the EarnQuest app.

## Getting Started

### 1. Clone & Setup

```bash
# Clone repository
git clone <repository-url>
cd cashflow

# Install dependencies
flutter pub get

# Get Manrope fonts from Google Fonts
# Place in assets/fonts/

# Configure Firebase
flutterfire configure --project=earnquest
```

### 2. Run the App

```bash
# Debug mode
flutter run

# Release mode
flutter run --release

# Specific platform
flutter run -d android
flutter run -d ios
flutter run -d chrome  # Web (if enabled)
```

### 3. Code Quality

```bash
# Analyze code
flutter analyze

# Format code
dart format lib/

# Run tests
flutter test

# Generate code coverage
flutter test --coverage
```

---

## Project Architecture

### State Management (Provider)

The app uses **Provider** for state management with two main providers:

#### UserProvider
Manages user-related state:
```dart
Provider<UserProvider>(
  create: (_) => UserProvider(),
)
```

**Key Methods:**
- `setUser(User user)` - Set user after login
- `updateBalance(double amount)` - Update balance
- `logout()` - Clear user data

**Usage:**
```dart
Consumer<UserProvider>(
  builder: (context, userProvider, _) {
    return Text('Balance: ₹${userProvider.user.availableBalance}');
  },
)
```

#### TaskProvider
Manages task-related state:
```dart
Provider<TaskProvider>(
  create: (_) => TaskProvider(),
)
```

**Key Methods:**
- `setTasks(List<Task> tasks)` - Load tasks
- `completeTask(String taskId)` - Mark task as complete
- `resetDailyProgress()` - Reset daily stats

---

## Component Development

### Creating a New Widget

**1. Stateless Widget (Recommended)**

```dart
class MyWidget extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const MyWidget({
    Key? key,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Your UI here
      ),
    );
  }
}
```

**2. Stateful Widget**

```dart
class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({Key? key}) : super(key: key);

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

### Using Theme Colors

```dart
// Primary color
Color primary = AppTheme.primaryColor;

// Text color
Color text = AppTheme.textPrimary;

// Background
Color bg = AppTheme.backgroundColor;

// Spacing
double padding = AppTheme.space16;

// Border radius
double radius = AppTheme.radiusM;

// Shadows
List<BoxShadow> shadow = AppTheme.cardShadow;
```

### Common UI Patterns

**Card with Shadow:**
```dart
Container(
  padding: const EdgeInsets.all(AppTheme.space16),
  decoration: BoxDecoration(
    color: AppTheme.surfaceColor,
    borderRadius: BorderRadius.circular(AppTheme.radiusM),
    boxShadow: AppTheme.cardShadow,
  ),
  child: // Your content
)
```

**Button:**
```dart
SizedBox(
  width: double.infinity,
  height: 48,
  child: ElevatedButton(
    onPressed: () {},
    child: const Text('Button Text'),
  ),
)
```

**Text Styles:**
```dart
// Headline
Text('Title', style: Theme.of(context).textTheme.headlineSmall)

// Body
Text('Content', style: Theme.of(context).textTheme.bodyMedium)

// Label
Text('Label', style: Theme.of(context).textTheme.labelLarge)
```

---

## Data Models

### Creating a New Model

```dart
class MyModel {
  final String id;
  final String name;
  final DateTime createdAt;

  MyModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  // From JSON
  factory MyModel.fromJson(Map<String, dynamic> json) {
    return MyModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : DateTime.now(),
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Copy with
  MyModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return MyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

---

## Navigation

### Current Navigation (Temporary)

The app uses a simple bottom navigation bar:

```dart
MainNavigationScreen(
  screens: [
    HomeScreen(),
    TasksScreen(),
    GamesScreen(),
    SpinScreen(),
  ],
)
```

### Future Navigation (GoRouter)

```dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'tasks',
          builder: (context, state) => const TasksScreen(),
        ),
      ],
    ),
  ],
);

MaterialApp.router(
  routerConfig: router,
)
```

---

## Working with Firebase

### Authentication

```dart
final authService = AuthService();

// Sign up
try {
  await authService.signUpWithEmail(
    email: email,
    password: password,
    displayName: displayName,
  );
} catch (e) {
  print('Sign up failed: $e');
}

// Sign in
try {
  await authService.signInWithEmail(
    email: email,
    password: password,
  );
} catch (e) {
  print('Sign in failed: $e');
}

// Sign out
await authService.signOut();
```

### Firestore Queries

```dart
final firestore = FirebaseFirestore.instance;

// Read single document
final doc = await firestore.collection('users').doc(userId).get();
final user = User.fromJson(doc.data()!);

// Read collection
final snapshot = await firestore.collection('tasks').get();
final tasks = snapshot.docs.map((doc) => Task.fromJson(doc.data())).toList();

// Real-time listener
firestore.collection('users').doc(userId).snapshots().listen((doc) {
  final user = User.fromJson(doc.data()!);
  print('User updated: ${user.displayName}');
});

// Add document
await firestore.collection('transactions').add({
  'userId': userId,
  'amount': 0.10,
  'timestamp': FieldValue.serverTimestamp(),
});

// Update document
await firestore.collection('users').doc(userId).update({
  'availableBalance': newBalance,
  'lastUpdated': FieldValue.serverTimestamp(),
});

// Delete document
await firestore.collection('users').doc(userId).delete();

// Batch operations
final batch = firestore.batch();
batch.set(ref1, data1);
batch.update(ref2, data2);
batch.delete(ref3);
await batch.commit();
```

---

## Error Handling

### Try-Catch Pattern

```dart
try {
  // Your code
} on FirebaseAuthException catch (e) {
  showErrorSnackbar(context, e.message ?? 'Auth error');
} on FirebaseException catch (e) {
  showErrorSnackbar(context, 'Firebase error: ${e.code}');
} catch (e) {
  showErrorSnackbar(context, 'Something went wrong');
}
```

### Show Error Dialog

```dart
void showErrorSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppTheme.errorColor,
      duration: const Duration(seconds: 3),
    ),
  );
}
```

---

## Testing

### Unit Tests

```dart
void main() {
  test('User balance calculation', () {
    final user = User(
      userId: '1',
      email: 'test@test.com',
      availableBalance: 100.0,
    );
    
    expect(user.availableBalance, 100.0);
    expect(user.canWithdraw, true); // if balance >= 50
  });
}
```

### Widget Tests

```dart
void main() {
  testWidgets('Balance card shows correct amount', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BalanceCard(
            balance: 125.50,
            onWithdraw: () {},
          ),
        ),
      ),
    );

    expect(find.text('₹125.50'), findsOneWidget);
  });
}
```

---

## Performance Optimization

### 1. Use const Constructors
```dart
// Good
const SizedBox(height: 16)

// Avoid
SizedBox(height: 16)
```

### 2. Efficient Rebuilds
```dart
// Use Consumer for selective rebuilds
Consumer<UserProvider>(
  builder: (context, userProvider, child) {
    return Text(userProvider.user.availableBalance.toString());
  },
  child: ExpensiveWidget(), // Doesn't rebuild
)
```

### 3. Image Optimization
```dart
// Use cached images
Image.network(
  imageUrl,
  cacheWidth: 400,
  cacheHeight: 400,
)
```

### 4. Lazy Loading
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListTile(title: Text(items[index]));
  },
)
```

---

## Debugging

### Print Logs
```dart
debugPrint('Debug info: $value');
```

### Use Breakpoints
1. Set breakpoint in code
2. Run with `flutter run`
3. Debugger will pause at breakpoint

### DevTools
```bash
flutter pub global activate devtools
flutter pub global run devtools

# Or from VS Code: Cmd+Shift+P → Open DevTools
```

### Monitor Performance
```dart
// Add to build methods
@override
Widget build(BuildContext context) {
  debugPrintBeginFrame('MyWidget');
  return Center(child: Text('Hello'));
}
```

---

## Naming Conventions

### Files
```
- snake_case.dart
- user_provider.dart
- login_screen.dart
```

### Classes
```
- PascalCase
- UserModel
- LoginScreen
```

### Variables & Methods
```
- camelCase
- userName
- calculateBalance()
```

### Constants
```
- CONSTANT_CASE (for compile-time constants)
- const double maxHeight = 100.0;

- camelCase (for runtime constants)
- final maxHeight = 100.0;
```

---

## Common Issues & Solutions

### Issue: Widget not rebuilding
**Solution:** Make sure you're calling `notifyListeners()` in Provider

### Issue: Firebase not initializing
**Solution:** Ensure `Firebase.initializeApp()` is called before `runApp()`

### Issue: Slow loading
**Solution:** Use `const` constructors and `ListView.builder` for lists

### Issue: Memory leaks
**Solution:** Always dispose TextEditingControllers and StreamSubscriptions

---

## Useful Commands

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run

# Build for release
flutter build apk --release
flutter build ios --release

# Generate coverage report
flutter test --coverage
lcov --list coverage/lcov.info  # View coverage

# Update dependencies
flutter pub upgrade

# Get pub packages from lockfile
flutter pub get

# Analyze code without running
flutter analyze

# Format code
dart format lib/
```

---

## Git Workflow

```bash
# Create feature branch
git checkout -b feature/feature-name

# Make changes and commit
git add .
git commit -m "feat: add new feature"

# Push to remote
git push origin feature/feature-name

# Create pull request on GitHub

# After approval, merge to main
git checkout main
git pull origin main
git merge feature/feature-name
git push origin main
```

---

## Commit Message Convention

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat` - New feature
- `fix` - Bug fix
- `refactor` - Code refactoring
- `style` - Code style changes
- `test` - Test additions
- `docs` - Documentation
- `chore` - Build, dependency changes

**Example:**
```
feat(auth): add email verification

Add email verification before account activation.
Users will receive verification link via email.

Closes #123
```

---

## Resources

- [Flutter Best Practices](https://flutter.dev/docs/testing/best-practices)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Provider Documentation](https://pub.dev/packages/provider)
- [Firebase Docs](https://firebase.google.com/docs)
- [Material Design 3](https://m3.material.io/)

---

**Last Updated:** November 22, 2025
**Version:** 1.0
