import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/cloudflare_workers_service.dart';
import '../../services/ad_service.dart';
import '../../core/utils/device_utils.dart';
import '../../providers/user_provider.dart';
import '../../providers/task_provider.dart';

class SpinScreen extends StatefulWidget {
  const SpinScreen({super.key});

  @override
  State<SpinScreen> createState() => _SpinScreenState();
}

class _SpinScreenState extends State<SpinScreen> {
  bool _isSpinning = false;
  double _rotation = 0;
  final CloudflareWorkersService _api = CloudflareWorkersService();
  final AdService _adService = AdService();
  String? _deviceId;

  @override
  void initState() {
    super.initState();
    _initializeDeviceId();
  }

  Future<void> _initializeDeviceId() async {
    try {
      _deviceId = await DeviceUtils.getDeviceId();
    } catch (e) {
      debugPrint('Error getting device ID: $e');
    }
  }

  Future<void> _startSpin() async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null || _deviceId == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not logged in')));
      }
      return;
    }

    if (_isSpinning) return;

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading rewarded ad...'),
            ],
          ),
        ),
      );
    }

    try {
      // Show rewarded ad first
      final adShown = await _adService.showRewardedAd(
        onRewardEarned: (reward) {
          debugPrint('Ad reward earned: $reward');
        },
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      if (!adShown) {
        // User closed ad without watching
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please watch the ad to spin'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Start spin animation
      if (mounted) {
        setState(() {
          _isSpinning = true;
          _rotation =
              (math.Random().nextDouble() * 360) +
              (360 * (5 + math.Random().nextDouble() * 3));
        });
      }

      // Wait for spin animation
      await Future.delayed(const Duration(seconds: 3));

      // Execute spin after ad and animation
      final result = await _api.executeSpin(
        userId: user.uid,
        deviceId: _deviceId!,
      );

      // Get reward amount
      final reward = result['reward'] as double? ?? 0.5;

      // Update state - check mounted after async
      if (!mounted) return;

      final userProvider = context.read<UserProvider>();
      await userProvider.updateBalance(reward);

      if (!mounted) return;

      final taskProvider = context.read<TaskProvider>();
      await taskProvider.recordSpinResult(user.uid, reward);

      if (mounted) {
        setState(() {
          _isSpinning = false;
        });
        _showSpinResult(reward);
      }
    } catch (e) {
      debugPrint('Error during spin: $e');
      if (mounted) {
        Navigator.pop(context);
        setState(() {
          _isSpinning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSpinResult(double reward) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: AppTheme.space16),
            Text(
              'You Won!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space12),
            Text(
              "You've earned ₹${reward.toStringAsFixed(2)}!",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: AppTheme.successColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Awesome!'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Spin & Win'), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppTheme.space16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Spin Wheel',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppTheme.space12),
                    Text(
                      "Today's Spins: 0/1",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space32),

              // Spinning Wheel (placeholder)
              Center(
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.elevatedShadow,
                  ),
                  child: Transform.rotate(
                    angle: _rotation * (math.pi / 180),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.secondaryColor,
                            AppTheme.tertiaryColor,
                            AppTheme.successColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.backgroundColor,
                          ),
                          child: const Center(
                            child: Text('🎰', style: TextStyle(fontSize: 32)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space32),

              // Spin Button
              Center(
                child: Column(
                  children: [
                    Text(
                      '⏰ Next spin in: 18h 23m',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space24),
                    SizedBox(
                      width: 180,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSpinning ? null : _startSpin,
                        child: const Text('Watch & Spin 📺'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space32),

              // Recent Winners
              Text(
                'Recent Winners',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppTheme.space12),

              _WinnerCard(name: 'Amit K.', amount: '₹1.00'),
              const SizedBox(height: AppTheme.space12),
              _WinnerCard(name: 'Sneha P.', amount: '₹0.50'),
              const SizedBox(height: AppTheme.space12),
              _WinnerCard(name: 'You', amount: '₹0.20 yesterday'),
            ],
          ),
        ),
      ),
    );
  }
}

class _WinnerCard extends StatelessWidget {
  final String name;
  final String amount;

  const _WinnerCard({required this.name, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          const Text('✨', style: TextStyle(fontSize: 24)),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Text(
              '$name won $amount',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
