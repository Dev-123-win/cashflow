import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../core/theme/app_theme.dart';
import '../widgets/floating_dock.dart';
import 'home/home_screen.dart';
import 'tasks/tasks_screen.dart';
import 'games/games_screen.dart';
import 'games/spin_screen.dart';

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

  final List<IconData> _icons = [
    Iconsax.home_2,
    Iconsax.task_square,
    Iconsax.game,
    Iconsax.medal_star,
  ];

  final List<String> _labels = ['Home', 'Tasks', 'Games', 'Spin'];

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
        backgroundColor: AppTheme.backgroundColor,
        extendBody: true, // Important for floating dock
        body: Stack(
          children: [
            // Main Content
            IndexedStack(index: _currentIndex, children: _screens),

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
