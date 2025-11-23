import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../../core/theme/app_theme.dart';
import '../../services/ad_service.dart';
import '../../services/firestore_service.dart';
import '../../services/request_deduplication_service.dart';
import '../../services/device_fingerprint_service.dart';
import '../../widgets/error_states.dart';

class WatchAdsScreen extends StatefulWidget {
  const WatchAdsScreen({super.key});

  @override
  State<WatchAdsScreen> createState() => _WatchAdsScreenState();
}

class _WatchAdsScreenState extends State<WatchAdsScreen> {
  late final AdService _adService;
  int _adsWatchedToday = 0;
  final int _maxAdsPerDay = 5;
  bool _isLoadingAd = false;

  final List<AdItem> _availableAds = [
    AdItem(
      id: '1',
      title: 'Brand Video Ad',
      description: '30 seconds',
      reward: 0.03,
      watched: false,
    ),
    AdItem(
      id: '2',
      title: 'Game Promotion',
      description: '30 seconds',
      reward: 0.03,
      watched: false,
    ),
    AdItem(
      id: '3',
      title: 'Shopping App',
      description: '30 seconds',
      reward: 0.03,
      watched: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _adService = AdService();
    _adService.loadRewardedAd();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _watchAd(AdItem ad) async {
    if (_adsWatchedToday >= _maxAdsPerDay) {
      StateSnackbar.showWarning(
        context,
        'Daily ad limit reached. Come back tomorrow!',
      );
      return;
    }

    setState(() => _isLoadingAd = true);

    try {
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
            final requestId = dedup.generateRequestId(user.uid, 'ad_view', {
              'adId': ad.id,
              'reward': ad.reward,
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
              ad.reward,
              requestId: requestId,
              deviceFingerprint: deviceFingerprint,
            );

            // Mark as processed in deduplication cache
            await dedup.recordRequest(
              requestId: requestId,
              requestHash: requestId.hashCode.toString(),
              success: true,
              transactionId:
                  '${ad.id}:${DateTime.now().millisecondsSinceEpoch}',
            );

            // Update UI
            if (mounted) {
              setState(() {
                _adsWatchedToday++;
                ad.watched = true;
              });

              // Show success message
              StateSnackbar.showSuccess(
                context,
                'Great! You earned ₹${ad.reward.toStringAsFixed(2)}',
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
        StateSnackbar.showWarning(context, 'Ad not ready. Please try again.');
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
                    'Today: $_adsWatchedToday/$_maxAdsPerDay ads',
                    style: Theme.of(context).textTheme.labelLarge,
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
                  const SizedBox(height: AppTheme.space12),
                  Text(
                    'Earned: ₹${(_adsWatchedToday * 0.03).toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space32),
            Text(
              'Available Ads',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTheme.space16),
            ..._availableAds.map((ad) => _buildAdCard(ad)),
          ],
        ),
      ),
    );
  }

  Widget _buildAdCard(AdItem ad) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space12),
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ad.title, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(
                  ad.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Earn: ₹${ad.reward.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.space16),
          ElevatedButton(
            onPressed: ad.watched || _isLoadingAd ? null : () => _watchAd(ad),
            child: Text(ad.watched ? 'Watched' : 'Watch'),
          ),
        ],
      ),
    );
  }
}

class AdItem {
  final String id;
  final String title;
  final String description;
  final double reward;
  bool watched;

  AdItem({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
    required this.watched,
  });
}
