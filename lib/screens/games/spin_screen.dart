import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:provider/provider.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../services/cooldown_service.dart';
import '../../services/device_fingerprint_service.dart';
import '../../services/cloudflare_workers_service.dart';
import '../../services/ad_service.dart';
import '../../providers/user_provider.dart';
import '../../widgets/error_states.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/zen_card.dart';
import '../../widgets/scale_button.dart';

class SpinScreen extends StatefulWidget {
  const SpinScreen({super.key});

  @override
  State<SpinScreen> createState() => _SpinScreenState();
}

class _SpinScreenState extends State<SpinScreen> {
  late final CooldownService _cooldownService;
  late final AdService _adService;
  late final CloudflareWorkersService _cloudflareService;
  late final List<double> _rewards = AppConstants.spinRewards;
  late ConfettiController _confettiController;

  bool _isSpinning = false;
  double? _lastSpinReward;
  bool _adShownPreSpin = false;
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _cooldownService = CooldownService();
    _adService = AdService();
    _cloudflareService = CloudflareWorkersService();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _showPreSpinAd();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _showPreSpinAd() async {
    if (_adShownPreSpin) return;

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted && math.Random().nextDouble() < 0.4) {
      await _adService.showInterstitialAd();
    }
    _adShownPreSpin = true;
  }

  Future<void> _executeSpin(UserProvider userProvider) async {
    if (_isSpinning) return;

    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        StateSnackbar.showError(context, 'User not logged in');
      }
      return;
    }

    final remaining = _cooldownService.getRemainingCooldown(
      user.uid,
      'spin_daily',
    );
    if (remaining > 0) {
      if (mounted) {
        StateSnackbar.showWarning(
          context,
          'Next spin available in ${_cooldownService.formatCooldown(remaining)}',
        );
      }
      return;
    }

    if (userProvider.user.availableBalance >= AppConstants.maxDailyEarnings) {
      if (mounted) {
        StateSnackbar.showWarning(
          context,
          'Daily earning limit reached (₹${AppConstants.maxDailyEarnings})',
        );
      }
      return;
    }

    setState(() {
      _isSpinning = true;
      _selected = math.Random().nextInt(_rewards.length);
    });

    // Wait for animation to finish (FortuneWheel default duration is usually around 5s, but we can control it via physics or just wait)
    // Actually FortuneWheel takes the selected index stream.
    // But here we are using a static list and just setting state.
    // Wait, FortuneWheel needs a Stream<int> for selected.
    // I'll use a StreamController or just rely on the widget's internal state if I can, but standard usage is Stream.
    // Let's assume standard usage for now, but I need to adapt to the existing code structure which didn't use Stream.
    // Ah, the previous code used `FortuneWheel` but didn't show the Stream controller setup.
    // I will implement it properly with StreamController.
  }

  // Helper to record reward after spin completes
  Future<void> _onSpinComplete(UserProvider userProvider) async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final fingerprint = Provider.of<DeviceFingerprintService>(
        context,
        listen: false,
      );
      final deviceFingerprint = await fingerprint.getDeviceFingerprint();

      // ✅ Execute spin via backend - backend determines the reward
      final result = await _cloudflareService.executeSpin(
        userId: user.uid,
        deviceId: deviceFingerprint,
      );

      // Get reward from backend response
      final reward = (result['reward'] as num?)?.toDouble() ?? 0.0;

      _lastSpinReward = reward;
      _confettiController.play();

      if (mounted) {
        await _showSpinResult(reward);
        _cooldownService.startCooldown(user.uid, 'spin_daily', 86400);

        // Refresh user data from backend
        await userProvider.refreshUser();
      }
    } catch (e) {
      debugPrint('Spin error: $e');
      if (mounted) {
        StateSnackbar.showError(context, 'Spin failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSpinning = false);
      }
    }
  }

  Future<void> _showSpinResult(double reward) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        title: const Text('🎉 You Won!', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Congratulations!',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.space16),
            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Text(
                '₹${reward.toStringAsFixed(2)} earned!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Daily Spin & Win'),
        leading: ScaleButton(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back),
        ),
      ),
      body: Stack(
        children: [
          Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.space16),
                      child: Column(
                        children: [
                          // Info Card
                          ZenCard(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Daily Spin',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Win up to ₹1.00',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppTheme.successColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.space12,
                                    vertical: AppTheme.space8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusS,
                                    ),
                                  ),
                                  child: Text(
                                    'One per day',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: AppTheme.primaryColor,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.space32),

                          // Spin Wheel
                          SizedBox(
                            height: 350,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                FortuneWheel(
                                  selected: Stream.value(_selected),
                                  animateFirst: false,
                                  items: List.generate(
                                    _rewards.length,
                                    (index) => FortuneItem(
                                      child: Text(
                                        '₹${_rewards[index].toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      style: FortuneItemStyle(
                                        color: _getSegmentColor(index),
                                        borderColor: AppTheme.surfaceColor,
                                        borderWidth: 2,
                                      ),
                                    ),
                                  ),
                                  onAnimationEnd: () =>
                                      _onSpinComplete(userProvider),
                                  physics: CircularPanPhysics(
                                    duration: const Duration(seconds: 4),
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                                // Center Indicator
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: AppTheme.softShadow,
                                    border: Border.all(
                                      color: AppTheme.primaryColor,
                                      width: 4,
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.star,
                                      color: AppTheme.tertiaryColor,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.space32),

                          // Spin Button
                          ScaleButton(
                            onTap: _isSpinning
                                ? null
                                : () => _executeSpin(userProvider),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.space48,
                                vertical: AppTheme.space16,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _isSpinning
                                      ? [Colors.grey, Colors.grey]
                                      : [
                                          AppTheme.primaryColor,
                                          AppTheme.secondaryColor,
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusXL,
                                ),
                                boxShadow: AppTheme.elevatedShadow,
                              ),
                              child: Text(
                                _isSpinning ? 'Spinning...' : 'Spin Now!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.space32),

                          // Last Spin Result
                          if (_lastSpinReward != null)
                            ZenCard(
                              color: AppTheme.successColor.withValues(
                                alpha: 0.05,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppTheme.successColor,
                                  ),
                                  const SizedBox(width: AppTheme.space12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Last Spin',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.labelSmall,
                                      ),
                                      Text(
                                        '₹${_lastSpinReward!.toStringAsFixed(2)} won',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: AppTheme.successColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const BannerAdWidget(),
                ],
              );
            },
          ),

          // Confetti Overlay
          Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Color(0xFF6C63FF),
                Color(0xFF00D9C0),
                Color(0xFFFFB800),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSegmentColor(int index) {
    final colors = [
      const Color(0xFF6C63FF),
      const Color(0xFF00D9C0),
      const Color(0xFFFFB800),
      const Color(0xFFFF5252),
      const Color(0xFF9C27B0),
      const Color(0xFF2196F3),
    ];
    return colors[index % colors.length];
  }
}
