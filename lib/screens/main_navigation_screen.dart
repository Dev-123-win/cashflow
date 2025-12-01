import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../widgets/floating_dock.dart';
import 'home/home_screen.dart';
import 'arcade/arcade_screen.dart';

import 'wallet_screen.dart';
import 'referral/referral_screen.dart';

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
    const WalletScreen(),
  ];

  final List<IconData> _icons = [
    Iconsax.home_2,
    Iconsax.game,

    Iconsax.people,
    Iconsax.wallet_2,
  ];

  final List<String> _labels = ['Home', 'Arcade', 'Referral', 'Wallet'];

  DateTime? _lastPressedAt;

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
        extendBody: true, // Important for floating dock
        body: Stack(
          children: [
            // Main Content
            Padding(
              padding: const EdgeInsets.only(
                bottom: 100,
              ), // Space for FloatingDock
              child: IndexedStack(index: _currentIndex, children: _screens),
            ),

            // Floating Dock
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: FloatingDock(
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
