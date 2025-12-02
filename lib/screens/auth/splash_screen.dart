import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../services/cloudflare_workers_service.dart';
import '../../widgets/custom_dialog.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkBackendHealth();
  }

  Future<void> _checkBackendHealth() async {
    // Wait for minimum splash duration
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      final isHealthy = await CloudflareWorkersService().healthCheck();
      if (isHealthy) {
        _navigateToNextScreen();
      } else {
        _showErrorDialog(
          'Backend is unreachable. Please check your connection.',
        );
      }
    } catch (e) {
      _showErrorDialog('Connection error: $e');
    }
  }

  void _navigateToNextScreen() {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ErrorDialog(
        title: 'Connection Error',
        message: message,
        onRetry: () {
          _checkBackendHealth();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.space24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Image.asset(
                  AppAssets.appIcon,
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
              ),
              const SizedBox(height: AppDimensions.space32),
              Text(
                'EarnQuest',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppDimensions.space8),
              Text(
                'Earn Money Made Easy',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppDimensions.space48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
