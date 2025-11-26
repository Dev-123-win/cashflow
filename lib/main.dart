import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'providers/user_provider.dart';
import 'providers/task_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/withdrawal/withdrawal_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/cooldown_service.dart';
import 'services/request_deduplication_service.dart';
import 'services/fee_calculation_service.dart';
import 'services/device_fingerprint_service.dart';
import 'services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hide system bars for immersive experience
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');

    // Enable Firestore offline persistence (reduces reads by 40-50%)
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    debugPrint('Firestore offline persistence enabled');
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

  // Initialize Google Mobile Ads and preload ads
  try {
    final adService = AdService();
    await adService.initialize(); // This also preloads all ads
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

  // Initialize CooldownService with persistent storage
  try {
    final cooldownService = CooldownService();
    await cooldownService.initialize();
    debugPrint('CooldownService initialized successfully');
  } catch (e) {
    debugPrint('CooldownService initialization error: $e');
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
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        scrollBehavior: const BouncingScrollBehavior(),
        home: const AuthenticationWrapper(),
        routes: {
          '/login': (context) => const AuthenticationScreen(),
          '/home': (context) => const MainNavigationScreen(),
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

        if (snapshot.hasData) {
          return const MainNavigationScreen();
        }

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

/// Custom scroll behavior for iOS-style bouncing on all platforms
class BouncingScrollBehavior extends ScrollBehavior {
  const BouncingScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}
