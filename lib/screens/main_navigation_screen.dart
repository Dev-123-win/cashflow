import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../core/di/service_locator.dart';
import '../services/local_notification_service.dart';
import '../widgets/physics_nav_bar.dart';
import 'home/home_screen.dart';
import 'arcade/arcade_screen.dart';
import 'referral/referral_screen.dart';
import 'withdrawal/withdrawal_screen.dart';
import 'profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ArcadeScreen(),
    const ReferralScreen(),
    const WithdrawalScreen(),
    const ProfileScreen(),
  ];

  final List<IconData> _icons = [
    Iconsax.home_2,
    Iconsax.game,
    Iconsax.people,
    Iconsax.wallet_2,
    Iconsax.user,
  ];

  final List<String> _labels = [
    'Home',
    'Arcade',
    'Referral',
    'Withdraw',
    'Profile',
  ];

  DateTime? _lastPressedAt;
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    final notificationService = getIt<LocalNotificationService>();
    _notificationSubscription = notificationService.navigationStream.listen((
      payload,
    ) {
      if (!mounted) return;

      debugPrint('Navigation payload received: $payload');

      if (payload == 'home') {
        setState(() => _currentIndex = 0);
      } else if (payload.contains('game') || payload.contains('arcade')) {
        setState(() => _currentIndex = 1); // Arcade tab
      } else if (payload == 'referral') {
        setState(() => _currentIndex = 2);
      } else if (payload == 'withdrawal') {
        setState(() => _currentIndex = 3);
      } else if (payload == 'profile') {
        setState(() => _currentIndex = 4);
      }
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastPressedAt == null ||
            now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = now;
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Press back again to exit'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        extendBody: true, // Important for navbar transparency
        body: Stack(
          children: [
            // Main Content
            Padding(
              padding: const EdgeInsets.only(
                bottom: 90,
              ), // Space for PhysicsNavBar
              child: IndexedStack(index: _currentIndex, children: _screens),
            ),

            // Physics Nav Bar
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: PhysicsNavBar(
                  currentIndex: _currentIndex,
                  onTap: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  icons: _icons,
                  labels: _labels,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
