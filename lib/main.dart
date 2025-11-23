import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'providers/user_provider.dart';
import 'providers/task_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/tasks/tasks_screen.dart';
import 'screens/games/games_screen.dart';
import 'screens/spin/spin_screen.dart';
import 'screens/withdrawal/withdrawal_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/cooldown_service.dart';
import 'services/request_deduplication_service.dart';
import 'services/fee_calculation_service.dart';
import 'services/device_fingerprint_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // Initialize AuthService
  try {
    final authService = AuthService();
    await authService.initialize();
    debugPrint('AuthService initialized successfully');
  } catch (e) {
    debugPrint('AuthService initialization error: $e');
  }

  // Initialize Google Mobile Ads
  try {
    await MobileAds.instance.initialize();
    debugPrint('Google Mobile Ads initialized successfully');
  } catch (e) {
    debugPrint('Google Mobile Ads initialization error: $e');
  }

  // Initialize Notification Service
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    debugPrint('Notification Service initialized successfully');
  } catch (e) {
    debugPrint('Notification Service initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => CooldownService()),
        Provider(create: (_) => RequestDeduplicationService()),
        Provider(create: (_) => FeeCalculationService()),
        Provider(create: (_) => DeviceFingerprintService()),
      ],
      child: MaterialApp(
        title: 'EarnQuest',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const AuthenticationWrapper(),
        routes: {
          '/login': (context) => const AuthenticationScreen(),
          '/home': (context) => const MainNavigationScreen(),
          '/tasks': (context) => const TasksScreen(),
          '/games': (context) => const GamesScreen(),
          '/spin': (context) => const SpinScreen(),
          '/withdrawal': (context) => const WithdrawalScreen(),
        },
      ),
    );
  }
}

/// Handles authentication state and navigation
class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Show splash for 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

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
          return const MainNavigationScreen();
        }

        // User is not logged in - show auth screen
        return const AuthenticationScreen();
      },
    );
  }
}

/// Toggles between Login, Sign Up, and Onboarding screens
class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  bool _isLoginMode = true;
  bool _showOnboarding = true;

  @override
  Widget build(BuildContext context) {
    // Show onboarding first time
    if (_showOnboarding) {
      return OnboardingScreen(
        onComplete: () {
          setState(() {
            _showOnboarding = false;
          });
        },
      );
    }

    if (_isLoginMode) {
      return LoginScreen(
        onSignUpTap: () {
          setState(() {
            _isLoginMode = false;
          });
        },
      );
    } else {
      return SignUpScreen(
        onLoginTap: () {
          setState(() {
            _isLoginMode = true;
          });
        },
      );
    }
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const TasksScreen(),
    const GamesScreen(),
    const SpinScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        indicatorColor: AppTheme.primaryColor.withValues(alpha: 0.1),
        selectedIndex: _currentIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.assignment),
            icon: Icon(Icons.assignment_outlined),
            label: 'Tasks',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.sports_esports),
            icon: Icon(Icons.sports_esports_outlined),
            label: 'Games',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.casino),
            icon: Icon(Icons.casino_outlined),
            label: 'Spin',
          ),
        ],
      ),
    );
  }
}
