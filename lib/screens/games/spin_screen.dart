import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../services/cooldown_service.dart';
import '../../services/request_deduplication_service.dart';
import '../../services/device_fingerprint_service.dart';
import '../../services/firestore_service.dart';
import '../../services/ad_service.dart';
import '../../providers/user_provider.dart';
import '../../widgets/error_states.dart';

class SpinScreen extends StatefulWidget {
  const SpinScreen({super.key});

  @override
  State<SpinScreen> createState() => _SpinScreenState();
}

class _SpinScreenState extends State<SpinScreen> {
  late final CooldownService _cooldownService;
  late final AdService _adService;
  late final FirestoreService _firestoreService;
  late final List<double> _rewards = AppConstants.spinRewards;

  bool _isSpinning = false;
  double? _lastSpinReward;
  bool _adShownPreSpin = false;

  @override
  void initState() {
    super.initState();
    _cooldownService = CooldownService();
    _adService = AdService();
    _firestoreService = FirestoreService();
    _showPreSpinAd();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Show pre-spin interstitial ad with 40% probability
  Future<void> _showPreSpinAd() async {
    if (_adShownPreSpin) return;

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted && math.Random().nextDouble() < 0.4) {
      await _adService.showInterstitialAd();
    }
    _adShownPreSpin = true;
  }

  /// Execute spin and record reward
  Future<void> _executeSpin(UserProvider userProvider) async {
    if (_isSpinning) return;

    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        StateSnackbar.showError(context, 'User not logged in');
      }
      return;
    }

    // Check cooldown
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

    // Check daily limit
    if (userProvider.user.availableBalance >= AppConstants.maxDailyEarnings) {
      if (mounted) {
        StateSnackbar.showWarning(
          context,
          'Daily earning limit reached (₹${AppConstants.maxDailyEarnings})',
        );
      }
      return;
    }

    setState(() => _isSpinning = true);

    try {
      // Randomly select reward from wheel options
      final selectedIndex = math.Random().nextInt(_rewards.length);
      final reward = _rewards[selectedIndex];

      // Ensure doesn't exceed daily cap
      final actualReward = math.min(
        reward,
        AppConstants.maxDailyEarnings - userProvider.user.availableBalance,
      );

      if (mounted) {
        await _recordSpinReward(userProvider, user.uid, actualReward);

        _lastSpinReward = actualReward;

        // Show result dialog
        await _showSpinResult(actualReward);

        // Set 24-hour cooldown
        _cooldownService.startCooldown(user.uid, 'spin_daily', 86400);

        // Update user balance
        await userProvider.updateBalance(
          userProvider.user.availableBalance + actualReward,
        );
      }
    } catch (e) {
      debugPrint('Spin error: $e');
      if (mounted) {
        StateSnackbar.showError(context, 'Spin failed: ${e.toString()}');
      }
    } finally {
      setState(() => _isSpinning = false);
    }
  }

  /// Record spin reward to Firestore
  Future<void> _recordSpinReward(
    UserProvider userProvider,
    String userId,
    double reward,
  ) async {
    try {
      final dedup = Provider.of<RequestDeduplicationService>(
        context,
        listen: false,
      );
      final fingerprint = Provider.of<DeviceFingerprintService>(
        context,
        listen: false,
      );

      final deviceFingerprint = await fingerprint.getDeviceFingerprint();

      final requestId = dedup.generateRequestId(userId, 'spin_result', {
        'reward': reward,
        'timestamp': DateTime.now().toIso8601String(),
        'deviceFingerprint': deviceFingerprint,
      });

      final cachedRecord = dedup.getFromLocalCache(requestId);
      if (cachedRecord != null && cachedRecord.success) {
        if (mounted) {
          StateSnackbar.showWarning(context, 'Spin already recorded');
        }
        return;
      }

      await _firestoreService.recordSpinResult(userId, reward);

      await dedup.recordRequest(
        requestId: requestId,
        requestHash: requestId.hashCode.toString(),
        success: true,
        transactionId: 'spin:${DateTime.now().millisecondsSinceEpoch}',
      );

      debugPrint(
        '✅ Spin reward recorded: ₹$reward for device: $deviceFingerprint',
      );
    } catch (e) {
      debugPrint('Error recording spin: $e');
      rethrow;
    }
  }

  /// Show spin result dialog
  Future<void> _showSpinResult(double reward) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 You Won!'),
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
                color: Colors.green.withValues(alpha: 0.1),
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Text(
                '₹${reward.toStringAsFixed(2)} earned!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.green,
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
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
          title: const Text('Daily Spin & Win'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    child: Column(
                      children: [
                        // Info Card
                        Container(
                          padding: const EdgeInsets.all(AppTheme.space16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusM,
                            ),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Daily Spin',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Win ₹0.05 - ₹1.00',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Colors.green,
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
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      border: Border.all(color: Colors.blue),
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusS,
                                      ),
                                    ),
                                    child: Text(
                                      'One per day',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: Colors.blue),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.space32),

                        // Spin Wheel Display
                        // Spin Wheel Display
                        Container(
                          padding: const EdgeInsets.all(AppTheme.space16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusM,
                            ),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 350,
                                child: FortuneWheel(
                                  items: List.generate(
                                    _rewards.length,
                                    (index) => FortuneItem(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: _getSegmentColor(index),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                              '₹',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              _rewards[index].toStringAsFixed(
                                                2,
                                              ),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  onAnimationEnd: () {
                                    debugPrint('Wheel animation ended');
                                  },
                                  physics: CircularPanPhysics(
                                    duration: const Duration(seconds: 3),
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppTheme.space16),
                              ElevatedButton.icon(
                                onPressed: _isSpinning
                                    ? null
                                    : () => _executeSpin(userProvider),
                                icon: Icon(
                                  _isSpinning
                                      ? Icons.hourglass_bottom
                                      : Icons.touch_app,
                                ),
                                label: Text(
                                  _isSpinning ? 'Spinning...' : 'Spin Now!',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.space32),

                        // Last Spin Result
                        if (_lastSpinReward != null)
                          Container(
                            padding: const EdgeInsets.all(AppTheme.space16),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.05),
                              border: Border.all(color: Colors.green),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusM,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: AppTheme.space12),
                                Expanded(
                                  child: Column(
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
                                            .titleSmall
                                            ?.copyWith(color: Colors.green),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: AppTheme.space32),

                        // How to Play
                        Container(
                          padding: const EdgeInsets.all(AppTheme.space16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusM,
                            ),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '❓ How to Play',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: AppTheme.space12),
                              Text(
                                '• Tap or fling the wheel to spin\n'
                                '• Land on a segment to win that amount\n'
                                '• You can spin once per day\n'
                                '• Winnings count toward your daily cap\n'
                                '• More spins available with ads',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Banner Ad
                _buildBannerAd(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBannerAd() {
    return Container(
      alignment: Alignment.center,
      width: AdSize.banner.width.toDouble(),
      height: AdSize.banner.height.toDouble(),
      child: _adService.getBannerAd() != null
          ? AdWidget(ad: _adService.getBannerAd()!)
          : Container(
              color: AppTheme.surfaceColor,
              child: const Center(
                child: Text('Loading ad...', style: TextStyle(fontSize: 12)),
              ),
            ),
    );
  }

  /// Get segment color based on reward amount
  Color _getSegmentColor(int index) {
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
    ];
    return colors[index % colors.length];
  }
}
