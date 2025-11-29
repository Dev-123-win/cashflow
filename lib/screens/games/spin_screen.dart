import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:provider/provider.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as math;
import 'dart:async';
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
  late final List<double> _rewards = AppConstants.spinRewards;
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

      // Find indices that match the reward
      final matchingIndices = <int>[];
      for (int i = 0; i < _rewards.length; i++) {
        if ((_rewards[i] - reward).abs() < 0.01) {
          matchingIndices.add(i);
        }
      }

      if (matchingIndices.isNotEmpty) {
        // Pick a random matching index
        targetIndex =
            matchingIndices[math.Random().nextInt(matchingIndices.length)];
      } else {
        // Fallback: Pick index with closest value
        double minDiff = double.infinity;
        for (int i = 0; i < _rewards.length; i++) {
          final diff = (_rewards[i] - reward).abs();
          if (diff < minDiff) {
            minDiff = diff;
            targetIndex = i;
          }
        }
      }

      // NEAR MISS LOGIC:
      // If reward is low (< 1.0), try to make it look like a near miss of a high reward (> 5.0)
      if (reward < 1.0) {
        // Find high reward indices
        final highRewardIndices = <int>[];
        for (int i = 0; i < _rewards.length; i++) {
          if (_rewards[i] >= 5.0) {
            highRewardIndices.add(i);
          }
        }

        if (highRewardIndices.isNotEmpty) {
          // Check if our target index is adjacent to any high reward index
          // If not, try to find a matching reward index that IS adjacent
          bool isAdjacent = false;
          for (final highIndex in highRewardIndices) {
            final prev = (highIndex - 1 + _rewards.length) % _rewards.length;
            final next = (highIndex + 1) % _rewards.length;
            if (targetIndex == prev || targetIndex == next) {
              isAdjacent = true;
              break;
            }
          }

          if (!isAdjacent && matchingIndices.length > 1) {
            // Try to switch to an adjacent one if available
            for (final matchIndex in matchingIndices) {
              for (final highIndex in highRewardIndices) {
                final prev =
                    (highIndex - 1 + _rewards.length) % _rewards.length;
                final next = (highIndex + 1) % _rewards.length;
                if (matchIndex == prev || matchIndex == next) {
                  targetIndex = matchIndex;
                  break;
                }
              }
            }
          }
        }
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

      if (mounted) {
        await _showSpinResult(_lastSpinReward!);
        _cooldownService.startCooldown(user.uid, 'spin_daily', 86400);

        // Refresh user data from backend
        await userProvider.refreshUser();

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
            const SizedBox(height: AppTheme.space16),
            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Text(
                '$reward Coins earned!',
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
                                      'Win up to 750 Coins',
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
                                  selected: _selectedController.stream,
                                  animateFirst: false,
                                  items: List.generate(
                                    _rewards.length,
                                    (index) => FortuneItem(
                                      child: Text(
                                        '${_rewards[index].toInt()}',
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
                            onTap: canSpin
                                ? () => _executeSpin(userProvider)
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.space48,
                                vertical: AppTheme.space16,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: canSpin
                                      ? [
                                          AppTheme.primaryColor,
                                          AppTheme.secondaryColor,
                                        ]
                                      : [Colors.grey, Colors.grey],
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusXL,
                                ),
                                boxShadow: AppTheme.elevatedShadow,
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
                                        '$_lastSpinReward Coins won',
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
