import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../../core/theme/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../services/ad_service.dart';
import '../../services/cloudflare_workers_service.dart';
import '../../services/device_fingerprint_service.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/error_states.dart';
import '../../providers/user_provider.dart';

class WatchAdsScreen extends StatefulWidget {
  const WatchAdsScreen({super.key});

  @override
  State<WatchAdsScreen> createState() => _WatchAdsScreenState();
}

class _WatchAdsScreenState extends State<WatchAdsScreen> {
  late final AdService _adService;
  int _adsWatchedToday = 0;
  final int _maxAdsPerDay = AppConstants.maxAdsPerDay;
  bool _isLoadingAd = false;
  int _totalEarned = 0;

  @override
  void initState() {
    super.initState();
    _adService = AdService();
    // Ensure rewarded ads are preloaded
    _adService.loadRewardedAd();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void>? _claimFuture;

  Future<void> _watchRewardedAd() async {
    if (_adsWatchedToday >= _maxAdsPerDay) {
      if (mounted) {
        StateSnackbar.showWarning(
          context,
          'Daily ad limit reached. Come back tomorrow!',
        );
      }
      return;
    }

    if (_claimFuture != null) return;

    _claimFuture = _executeWatchRewardedAd();
    try {
      await _claimFuture;
    } finally {
      if (mounted) {
        setState(() {
          _claimFuture = null;
        });
      }
    }
  }

  Future<void> _executeWatchRewardedAd() async {
    setState(() {
      _isLoadingAd = true;
    });

    try {
      // Show the rewarded ad using Google's native ad implementation
      final success = await _adService.showRewardedAd(
        onRewardEarned: (rewardAmount) async {
          // Get auth and services
          final user = fb_auth.FirebaseAuth.instance.currentUser;
          if (user == null) {
            if (mounted) {
              StateSnackbar.showError(context, 'User not logged in');
            }
            return;
          }

          final userProvider = Provider.of<UserProvider>(
            context,
            listen: false,
          );
          final reward = AppConstants.rewardedAdReward;

          // Optimistic Update
          userProvider.addOptimisticCoins(reward);

          try {
            final fingerprint = Provider.of<DeviceFingerprintService>(
              context,
              listen: false,
            );
            final cloudflareService = CloudflareWorkersService();

            // Get device fingerprint
            final deviceFingerprint = await fingerprint.getDeviceFingerprint();

            // Generate unique request ID for deduplication
            final requestId =
                'ad_rewarded_${DateTime.now().millisecondsSinceEpoch}';

            // Record ad view via Cloudflare Worker
            final result = await cloudflareService
                .recordAdView(
                  userId: user.uid,
                  adType: 'rewarded',
                  deviceId: deviceFingerprint,
                  requestId: requestId,
                )
                .timeout(
                  const Duration(seconds: 15),
                  onTimeout: () {
                    throw Exception('Request timed out');
                  },
                );

            // Update UI from Backend Response
            if (result['success'] == true) {
              final newBalance = result['newBalance'];
              if (newBalance != null) {
                userProvider.updateLocalState(coins: newBalance);
                userProvider.confirmOptimisticCoins(reward);
              }

              if (mounted) {
                setState(() {
                  _adsWatchedToday++;
                  _totalEarned += reward;
                });

                // Show success message
                StateSnackbar.showSuccess(
                  context,
                  'Great! You earned $reward Coins',
                );
              }
            }
          } catch (e) {
            debugPrint('Error recording ad view: $e');
            // Rollback on error
            userProvider.rollbackOptimisticCoins(reward);
            if (mounted) {
              StateSnackbar.showError(
                context,
                'Failed to claim reward: ${e.toString().replaceAll('Exception: ', '')}',
              );
            }
          }
        },
      );

      if (!success && mounted) {
        StateSnackbar.showWarning(context, 'Ad not ready. Loading...');
        // Retry loading
        _adService.loadRewardedAd();
      }
    } catch (e) {
      if (mounted) {
        StateSnackbar.showError(context, 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAd = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primary;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final surfaceVariant = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariantLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: const Text('Watch & Earn'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Earnings Summary
            Container(
              padding: const EdgeInsets.all(AppDimensions.space16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ads Watched',
                            style: theme.textTheme.labelLarge,
                          ),
                          const SizedBox(height: AppDimensions.space8),
                          Text(
                            '$_adsWatchedToday/$_maxAdsPerDay',
                            style: theme.textTheme.headlineSmall,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Earned Today',
                            style: theme.textTheme.labelLarge,
                          ),
                          const SizedBox(height: AppDimensions.space8),
                          Text(
                            '$_totalEarned Coins',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _adsWatchedToday / _maxAdsPerDay,
                      minHeight: 8,
                      backgroundColor: surfaceVariant,
                      valueColor: AlwaysStoppedAnimation(primaryColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space32),

            // Info Box
            Container(
              padding: const EdgeInsets.all(AppDimensions.space16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 20),
                      const SizedBox(width: AppDimensions.space12),
                      Expanded(
                        child: Text(
                          'How to Earn',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space12),
                  Text(
                    '• Watch full video advertisements\n• Get ${AppConstants.rewardedAdReward} Coins per ad\n• Limit: $_maxAdsPerDay ads per day\n• Ads reset daily at midnight',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space32),

            // Watch Ad Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_adsWatchedToday >= _maxAdsPerDay || _isLoadingAd)
                    ? null
                    : _watchRewardedAd,
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                child: _isLoadingAd
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Loading Ad...'),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Watch Video Ad'),
                          if (_adsWatchedToday < _maxAdsPerDay)
                            Text(
                              'Earn ${AppConstants.rewardedAdReward} Coins',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
              ),
            ),

            if (_adsWatchedToday >= _maxAdsPerDay)
              Padding(
                padding: const EdgeInsets.only(top: AppDimensions.space16),
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.space12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, color: Colors.orange),
                      const SizedBox(width: AppDimensions.space12),
                      Expanded(
                        child: Text(
                          'Daily ad limit reached. Claim more tomorrow!',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppDimensions.space32),
          ],
        ),
      ),
    );
  }
}
