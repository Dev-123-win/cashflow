import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:provider/provider.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as math;
import 'dart:async';
import '../../core/theme/colors.dart';
import '../../core/constants/dimensions.dart';
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
import '../../widgets/custom_dialog.dart';

class SpinScreen extends StatefulWidget {
  const SpinScreen({super.key});

  @override
  State<SpinScreen> createState() => _SpinScreenState();
}

class _SpinScreenState extends State<SpinScreen> {
  late final CooldownService _cooldownService;
  late final AdService _adService;
  late final CloudflareWorkersService _cloudflareService;
  late List<double> _rewards;
  late ConfettiController _confettiController;
  final StreamController<int> _selectedController =
      StreamController<int>.broadcast();

  bool _isSpinning = false;
  int? _lastSpinReward;
  bool _adShownPreSpin = false;

  @override
  void initState() {
    super.initState();
    _cooldownService = CooldownService();
    _adService = AdService();
    _cloudflareService = CloudflareWorkersService();
    // Create a mutable copy of the rewards
    _rewards = List<double>.from(AppConstants.spinRewards);
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _showPreSpinAd();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _selectedController.close();
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

    if (userProvider.user.coins >= AppConstants.maxDailyCoins) {
      if (mounted) {
        StateSnackbar.showWarning(
          context,
          'Daily earning limit reached (${AppConstants.maxDailyCoins} Coins)',
        );
      }
      return;
    }

    final fingerprint = Provider.of<DeviceFingerprintService>(
      context,
      listen: false,
    );

    // Check backend health before spinning
    final isBackendHealthy = await _cloudflareService.healthCheck();
    if (!isBackendHealthy) {
      if (mounted) {
        StateSnackbar.showError(
          context,
          'Cannot connect to server. Please try again later.',
        );
      }
      return;
    }

    setState(() {
      _isSpinning = true;
    });

    try {
      final deviceFingerprint = await fingerprint.getDeviceFingerprint();

      // Execute spin via backend FIRST
      final result = await _cloudflareService.executeSpin(
        userId: user.uid,
        deviceId: deviceFingerprint,
      );

      final reward = (result['reward'] as num?)?.toInt() ?? 0;
      _lastSpinReward = reward;

      // Determine target index
      int targetIndex = -1;

      // Check if exact reward exists
      for (int i = 0; i < _rewards.length; i++) {
        if ((_rewards[i] - reward).abs() < 0.01) {
          targetIndex = i;
          break;
        }
      }

      // If reward not found on wheel, replace the closest value
      if (targetIndex == -1) {
        double minDiff = double.infinity;
        int closestIndex = 0;

        for (int i = 0; i < _rewards.length; i++) {
          final diff = (_rewards[i] - reward).abs();
          if (diff < minDiff) {
            minDiff = diff;
            closestIndex = i;
          }
        }

        // Update the wheel segment to show the ACTUAL reward
        setState(() {
          _rewards[closestIndex] = reward.toDouble();
        });
        targetIndex = closestIndex;
      }

      // Start the visual spin
      _selectedController.add(targetIndex);
    } catch (e) {
      debugPrint('Spin error: $e');
      if (mounted) {
        StateSnackbar.showError(context, 'Spin failed: ${e.toString()}');
        setState(() => _isSpinning = false);
      }
    }
  }

  // Helper to record reward after spin completes
  Future<void> _onSpinComplete(UserProvider userProvider) async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null || _lastSpinReward == null) {
      setState(() => _isSpinning = false);
      return;
    }

    try {
      _confettiController.play();

      // Optimistic Update
      userProvider.addOptimisticCoins(_lastSpinReward!);

      if (mounted) {
        await _showSpinResult(_lastSpinReward!);
        _cooldownService.startCooldown(user.uid, 'spin_daily', 86400);

        // Sync with backend in background
        userProvider.refreshUser().catchError((e) {
          debugPrint('Error refreshing user data: $e');
        });

        // Check for Ad Break
        await _adService.checkAdBreak();
      }
    } catch (e) {
      debugPrint('Error showing result: $e');
    } finally {
      if (mounted) {
        setState(() => _isSpinning = false);
      }
    }
  }

  Future<void> _showSpinResult(int reward) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomDialog(
        title: '🎉 You Won!',
        emoji: '🎰',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Congratulations!',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimensions.space16),
            Container(
              padding: const EdgeInsets.all(AppDimensions.space16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Text(
                '$reward Coins earned!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primary;
    final secondaryColor = isDark ? AppColors.accentDark : AppColors.accent;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final tertiaryColor = AppColors.warning;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
              final user = fb_auth.FirebaseAuth.instance.currentUser;
              final remaining = user != null
                  ? _cooldownService.getRemainingCooldown(
                      user.uid,
                      'spin_daily',
                    )
                  : 0;
              final canSpin = remaining <= 0 && !_isSpinning;

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppDimensions.space16),
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
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Win up to 750 Coins',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppDimensions.space12,
                                    vertical: AppDimensions.space8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusS,
                                    ),
                                  ),
                                  child: Text(
                                    'One per day',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppDimensions.space32),

                          // Spin Wheel
                          SizedBox(
                            height: 350,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Decorative Lights Ring
                                SizedBox(
                                  width: 320,
                                  height: 320,
                                  child: CustomPaint(
                                    painter: WheelLightsPainter(
                                      primaryColor: primaryColor,
                                    ),
                                  ),
                                ),

                                // The Wheel
                                Padding(
                                  padding: const EdgeInsets.all(
                                    16.0,
                                  ), // Space for lights
                                  child: FortuneWheel(
                                    selected: _selectedController.stream,
                                    animateFirst: false,
                                    items: List.generate(
                                      _rewards.length,
                                      (index) => FortuneItem(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${_rewards[index].toInt()}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Image.asset(
                                              'assets/icons/Coin.png',
                                              width: 16,
                                              height: 16,
                                            ),
                                          ],
                                        ),
                                        style: FortuneItemStyle(
                                          color: _getSegmentColor(index),
                                          borderColor: surfaceColor,
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
                                ),

                                // Center Indicator
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: primaryColor,
                                      width: 4,
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.star,
                                      color: tertiaryColor,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppDimensions.space32),

                          // Spin Button
                          ScaleButton(
                            onTap: canSpin
                                ? () => _executeSpin(userProvider)
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.space48,
                                vertical: AppDimensions.space16,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: canSpin
                                      ? [primaryColor, secondaryColor]
                                      : [Colors.grey, Colors.grey],
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusXL,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (canSpin ? primaryColor : Colors.grey)
                                            .withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Text(
                                _isSpinning
                                    ? 'Spinning...'
                                    : remaining > 0
                                    ? 'Wait ${_cooldownService.formatCooldown(remaining)}'
                                    : 'Spin Now!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppDimensions.space32),

                          // Last Spin Result
                          if (_lastSpinReward != null)
                            ZenCard(
                              color: AppColors.success.withValues(alpha: 0.05),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: AppDimensions.space12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Last Spin',
                                        style: theme.textTheme.labelSmall,
                                      ),
                                      Text(
                                        '$_lastSpinReward Coins won',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              color: AppColors.success,
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

class WheelLightsPainter extends CustomPainter {
  final int lightsCount;
  final Color color;
  final Color primaryColor;

  WheelLightsPainter({
    this.lightsCount = 12,
    this.color = Colors.white,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final borderPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    // Draw outer ring
    canvas.drawCircle(center, radius, borderPaint);

    // Draw lights
    for (int i = 0; i < lightsCount; i++) {
      final angle = (2 * math.pi * i) / lightsCount;
      final x = center.dx + (radius - 10) * math.cos(angle);
      final y = center.dy + (radius - 10) * math.sin(angle);

      // Draw glow
      canvas.drawCircle(Offset(x, y), 6, paint);

      // Draw core
      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
