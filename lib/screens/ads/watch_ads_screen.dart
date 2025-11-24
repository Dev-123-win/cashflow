import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../../core/theme/app_theme.dart';
import '../../services/ad_service.dart';
import '../../services/firestore_service.dart';
import '../../services/request_deduplication_service.dart';
import '../../services/device_fingerprint_service.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/error_states.dart';

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
  double _totalEarned = 0.0;

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

    setState(() => _isLoadingAd = true);

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

          try {
            // Get deduplication and fingerprinting services
            final dedup = Provider.of<RequestDeduplicationService>(
              context,
              listen: false,
            );
            final fingerprint = Provider.of<DeviceFingerprintService>(
              context,
              listen: false,
            );
            final firestore = FirestoreService();

            // Get device fingerprint
            final deviceFingerprint = await fingerprint.getDeviceFingerprint();

            // Generate unique request ID for deduplication
            final requestId = dedup
                .generateRequestId(user.uid, 'ad_view_rewarded', {
                  'timestamp': DateTime.now().millisecondsSinceEpoch,
                  'reward': AppConstants.rewardedAdReward,
                });

            // Check if already processed (prevents duplicate earnings)
            final cachedRecord = dedup.getFromLocalCache(requestId);
            if (cachedRecord != null && cachedRecord.success) {
              if (mounted) {
                StateSnackbar.showWarning(context, 'Ad reward already claimed');
              }
              return;
            }

            // Record ad view via Firestore with deduplication fields
            await firestore.recordAdView(
              user.uid,
              'rewarded',
              AppConstants.rewardedAdReward,
              requestId: requestId,
              deviceFingerprint: deviceFingerprint,
            );

            // Mark as processed in deduplication cache
            await dedup.recordRequest(
              requestId: requestId,
              requestHash: requestId.hashCode.toString(),
              success: true,
              transactionId: 'ad_${DateTime.now().millisecondsSinceEpoch}',
            );

            // Update UI
            if (mounted) {
              setState(() {
                _adsWatchedToday++;
                _totalEarned += AppConstants.rewardedAdReward;
              });

              // Show success message
              StateSnackbar.showSuccess(
                context,
                'Great! You earned ₹${AppConstants.rewardedAdReward.toStringAsFixed(2)}',
              );
            }
          } catch (e) {
            debugPrint('Error recording ad view: $e');
            if (mounted) {
              StateSnackbar.showError(
                context,
                'Failed to claim reward: ${e.toString()}',
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
        setState(() => _isLoadingAd = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: const Text('Watch & Earn'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Earnings Summary
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ads Watched',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: AppTheme.space8),
                          Text(
                            '$_adsWatchedToday/$_maxAdsPerDay',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Earned Today',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: AppTheme.space8),
                          Text(
                            '₹${_totalEarned.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(color: AppTheme.primaryColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _adsWatchedToday / _maxAdsPerDay,
                      minHeight: 8,
                      backgroundColor: AppTheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space32),

            // Info Box
            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(color: AppTheme.tertiaryColor, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 20),
                      const SizedBox(width: AppTheme.space12),
                      Expanded(
                        child: Text(
                          'How to Earn',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space12),
                  Text(
                    '• Watch full video advertisements\n• Get ₹${AppConstants.rewardedAdReward.toStringAsFixed(2)} per ad\n• Limit: $_maxAdsPerDay ads per day\n• Ads reset daily at midnight',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space32),

            // Watch Ad Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_adsWatchedToday >= _maxAdsPerDay || _isLoadingAd)
                    ? null
                    : _watchRewardedAd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
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
                              'Earn ₹${AppConstants.rewardedAdReward.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: Colors.white),
                            ),
                        ],
                      ),
              ),
            ),

            if (_adsWatchedToday >= _maxAdsPerDay)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.space16),
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.space12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, color: Colors.orange),
                      const SizedBox(width: AppTheme.space12),
                      Expanded(
                        child: Text(
                          'Daily ad limit reached. Claim more tomorrow!',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppTheme.space32),
          ],
        ),
      ),
    );
  }
}
