import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'services/local_notification_service.dart';
import 'services/request_deduplication_service.dart';
import 'services/fee_calculation_service.dart';
import 'services/device_fingerprint_service.dart';
import 'services/ad_service.dart';
import 'core/di/service_locator.dart';
import 'widgets/custom_dialog.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup Service Locator
  try {
    await setupServiceLocator();
  } catch (e) {
    debugPrint('Service Locator initialization error: $e');
    runApp(ErrorApp(message: 'Failed to initialize app services: $e'));
    return;
  }

  // ✅ CRITICAL FIX: Don't hide system UI globally (only for games)
  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // 1. Initialize Firebase (Critical - Blocking)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');

    // Enable Firestore offline persistence with cache limit (100MB)
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes:
          100 * 1024 * 1024, // 100 MB limit (prevents storage bloat)
    );
    debugPrint('Firestore offline persistence enabled with 100MB limit');
  } catch (e) {
    debugPrint('FATAL: Firebase initialization error: $e');
    // ✅ CRITICAL FIX: Stop app if Firebase fails (all features depend on it)
    runApp(
      ErrorApp(
        message:
            'Failed to initialize Firebase. Please check your internet connection and try again.',
      ),
    );
    return;
  }

  // 2. Initialize AuthService (Critical - Blocking for navigation state)
  try {
    final authService = AuthService();
    await authService.initialize();
    debugPrint('AuthService initialized successfully');
  } catch (e) {
    debugPrint('FATAL: AuthService initialization error: $e');
    runApp(
      ErrorApp(
        message:
            'Failed to initialize authentication service. Please restart the app.',
      ),
    );
    return;
  }

  // 3. Initialize non-critical services in parallel
  // This significantly reduces startup time by not waiting for each one sequentially
  await Future.wait([
    // Google Mobile Ads
    Future(() async {
      try {
        final adService = getIt<AdService>();
        await adService.initialize(); // This also preloads all ads
        debugPrint('Google Mobile Ads initialized successfully');
      } catch (e) {
        debugPrint('Google Mobile Ads initialization error: $e');
        // Non-critical: App can function without ads
      }
    }),

    // Local Notification Service
    Future(() async {
      try {
        final notificationService = getIt<LocalNotificationService>();
        await notificationService.initialize();

        // Request permissions (Android 13+)
        await notificationService.requestPermissions();

        await notificationService.scheduleDailyReminder();
        await notificationService.scheduleStreakReminder();
        await notificationService.scheduleEngagementNotifications();
        debugPrint('Local Notification Service initialized');
      } catch (e) {
        debugPrint('Local Notification Service initialization error: $e');
        // Non-critical: App can function without notifications
      }
    }),
  ]);

  runApp(const MyApp());
}

/// Error screen shown when critical initialization fails
class ErrorApp extends StatelessWidget {
  final String message;

  const ErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade700),
                const SizedBox(height: 24),
                Text(
                  'Initialization Error',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.red.shade800),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Restart app (requires platform-specific implementation)
                    SystemNavigator.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Exit App'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        Provider(create: (_) => getIt<RequestDeduplicationService>()),
        Provider(create: (_) => getIt<FeeCalculationService>()),
        Provider(create: (_) => getIt<DeviceFingerprintService>()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
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
  bool _showOnboarding = true;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
    _checkRootStatus();
    // Show splash for 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  Future<void> _checkRootStatus() async {
    final deviceService = DeviceFingerprintService();
    final securityStatus = await deviceService.getDeviceSecurityStatus();
    final riskScore = await deviceService.getSecurityRiskScore();

    // Build warning message based on security issues
    List<String> warnings = [];

    if (securityStatus['isJailbroken'] == true) {
      warnings.add('• Device is rooted/jailbroken');
    }
    if (securityStatus['isRealDevice'] == false) {
      warnings.add('• Running on an emulator');
    }
    if (securityStatus['isMockLocation'] == true) {
      warnings.add('• Location mocking is enabled');
    }
    if (securityStatus['isDevelopmentMode'] == true) {
      warnings.add('• Developer mode is enabled');
    }
    if (securityStatus['isOnExternalStorage'] == true) {
      warnings.add('• App is installed on external storage');
    }

    // Show warning if there are any security issues
    if (warnings.isNotEmpty && mounted) {
      String severity = riskScore >= 40
          ? 'High Risk'
          : riskScore >= 20
          ? 'Medium Risk'
          : 'Low Risk';

      showDialog(
        context: context,
        barrierDismissible: riskScore < 40,
        builder: (context) => WarningDialog(
          title: 'Security Warning ($severity)',
          message:
              'The following security issues were detected:\n\n${warnings.join('\n')}\n\n${riskScore >= 40 ? 'For security reasons, this app cannot run on this device.' : 'Some features may not work correctly. Your account may be subject to additional verification.'}',
          confirmText: riskScore < 40 ? 'I Understand' : 'Exit App',
          onConfirm: () {
            if (riskScore >= 40) {
              SystemNavigator.pop();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      );
    }
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('onboarding_completed') ?? false;
    if (mounted) {
      setState(() {
        _showOnboarding = !completed;
      });
    }
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
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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

        return AuthenticationScreen(showOnboarding: _showOnboarding);
      },
    );
  }
}

/// Toggles between Login, Sign Up, and Onboarding screens
class AuthenticationScreen extends StatefulWidget {
  final bool showOnboarding;
  const AuthenticationScreen({super.key, this.showOnboarding = true});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  bool _isLoginMode = true;
  late bool _showOnboarding;

  @override
  void initState() {
    super.initState();
    _showOnboarding = widget.showOnboarding;
  }

  @override
  Widget build(BuildContext context) {
    // Show onboarding first time
    if (_showOnboarding) {
      return OnboardingScreen(
        onComplete: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('onboarding_completed', true);
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
