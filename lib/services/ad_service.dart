import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import 'cloudflare_workers_service.dart';
import 'device_fingerprint_service.dart';

/// Service responsible for loading, showing and tracking ad interactions.
/// All ad view earnings are recorded via the Cloudflare Workers backend.
class AdService {
  // -----------------------------------------------------------------
  // Singleton pattern
  // -----------------------------------------------------------------
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // -----------------------------------------------------------------
  // Backend services
  // -----------------------------------------------------------------
  final CloudflareWorkersService _cloudflare = CloudflareWorkersService();
  final DeviceFingerprintService _deviceFingerprint =
      DeviceFingerprintService();

  // -----------------------------------------------------------------
  // Initialization state
  // -----------------------------------------------------------------
  bool _isInitialized = false;

  /// Initialise Google Mobile Ads SDK and preload all ad formats.
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('✅ Google Mobile Ads initialized successfully');
      _preloadAllAds();
    } catch (e) {
      debugPrint('❌ Failed to initialise Google Mobile Ads: $e');
    }
  }

  // -----------------------------------------------------------------
  // Pre‑load all ad formats for a smooth user experience.
  // -----------------------------------------------------------------
  void _preloadAllAds() {
    loadInterstitialAd();
    loadRewardedAd();
    loadRewardedInterstitialAd();
    loadAppOpenAd();
    createBannerAd();
    debugPrint('🔄 All ads preloading in background');
  }

  // -----------------------------------------------------------------
  // Banner ad handling
  // -----------------------------------------------------------------
  BannerAd? _bannerAd;

  void createBannerAd() {
    if (_bannerAd != null) return;
    _bannerAd = BannerAd(
      adUnitId: AppConstants.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => debugPrint('✅ Banner Ad loaded'),
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ Banner Ad failed to load: ${error.message}');
          ad.dispose();
          _bannerAd = null;
        },
      ),
    );
    _bannerAd?.load();
  }

  BannerAd? getBannerAd() => _bannerAd;
  void disposeBannerAd() => _bannerAd?.dispose();

  // -----------------------------------------------------------------
  // Interstitial ad handling
  // -----------------------------------------------------------------
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  Future<void> loadInterstitialAd() async {
    await InterstitialAd.load(
      adUnitId: AppConstants.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          debugPrint('✅ Interstitial Ad loaded');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isInterstitialAdReady = false;
          debugPrint('❌ Interstitial Ad failed to load: ${error.message}');
        },
      ),
    );
  }

  Future<void> showInterstitialAd() async {
    if (_isInterstitialAdReady) {
      _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (_) =>
            debugPrint('✅ Interstitial Ad showed'),
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('✅ Interstitial Ad dismissed');
          ad.dispose();
          _isInterstitialAdReady = false;
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('❌ Interstitial Ad failed to show: ${error.message}');
          ad.dispose();
          _isInterstitialAdReady = false;
        },
      );
      await _interstitialAd?.show();
    } else {
      debugPrint('⚠️ Interstitial Ad not ready');
      loadInterstitialAd();
    }
  }

  // -----------------------------------------------------------------
  // Rewarded ad handling
  // -----------------------------------------------------------------
  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;

  Future<void> loadRewardedAd() async {
    await RewardedAd.load(
      adUnitId: AppConstants.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          debugPrint('✅ Rewarded Ad loaded');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isRewardedAdReady = false;
          debugPrint('❌ Rewarded Ad failed to load: ${error.message}');
        },
      ),
    );
  }

  Future<bool> showRewardedAd({required Function(int) onRewardEarned}) async {
    if (_isRewardedAdReady) {
      _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (_) => debugPrint('✅ Rewarded Ad showed'),
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('✅ Rewarded Ad dismissed');
          ad.dispose();
          _isRewardedAdReady = false;
          loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('❌ Rewarded Ad failed to show: ${error.message}');
          ad.dispose();
          _isRewardedAdReady = false;
        },
      );
      await _rewardedAd?.show(
        onUserEarnedReward: (_, reward) {
          debugPrint('🎉 User earned reward: ${reward.amount}');
          onRewardEarned(reward.amount.toInt());
        },
      );
      return true;
    } else {
      debugPrint('⚠️ Rewarded Ad not ready');
      loadRewardedAd();
      return false;
    }
  }

  // -----------------------------------------------------------------
  // Rewarded Interstitial ad handling
  // -----------------------------------------------------------------
  RewardedInterstitialAd? _rewardedInterstitialAd;
  bool _isRewardedInterstitialAdReady = false;

  Future<void> loadRewardedInterstitialAd() async {
    await RewardedInterstitialAd.load(
      adUnitId: AppConstants.rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd = ad;
          _isRewardedInterstitialAdReady = true;
          debugPrint('✅ Rewarded Interstitial Ad loaded');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isRewardedInterstitialAdReady = false;
          debugPrint(
            '❌ Rewarded Interstitial Ad failed to load: ${error.message}',
          );
        },
      ),
    );
  }

  Future<bool> showRewardedInterstitialAd({
    required Function(int) onRewardEarned,
  }) async {
    if (_isRewardedInterstitialAdReady) {
      _rewardedInterstitialAd?.fullScreenContentCallback =
          FullScreenContentCallback(
            onAdShowedFullScreenContent: (_) =>
                debugPrint('✅ Rewarded Interstitial Ad showed'),
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('✅ Rewarded Interstitial Ad dismissed');
              ad.dispose();
              _isRewardedInterstitialAdReady = false;
              loadRewardedInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint(
                '❌ Rewarded Interstitial Ad failed to show: ${error.message}',
              );
              ad.dispose();
              _isRewardedInterstitialAdReady = false;
            },
          );
      await _rewardedInterstitialAd?.show(
        onUserEarnedReward: (_, reward) {
          debugPrint('🎉 User earned reward: ${reward.amount}');
          onRewardEarned(reward.amount.toInt());
        },
      );
      return true;
    } else {
      debugPrint('⚠️ Rewarded Interstitial Ad not ready');
      loadRewardedInterstitialAd();
      return false;
    }
  }

  // -----------------------------------------------------------------
  // App Open ad handling
  // -----------------------------------------------------------------
  AppOpenAd? _appOpenAd;
  bool _isAppOpenAdReady = false;

  Future<void> loadAppOpenAd() async {
    await AppOpenAd.load(
      adUnitId: AppConstants.appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isAppOpenAdReady = true;
          debugPrint('✅ App Open Ad loaded');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isAppOpenAdReady = false;
          debugPrint('❌ App Open Ad failed to load: ${error.message}');
        },
      ),
    );
  }

  Future<void> showAppOpenAd() async {
    if (_isAppOpenAdReady) {
      _appOpenAd?.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (_) => debugPrint('✅ App Open Ad showed'),
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('✅ App Open Ad dismissed');
          ad.dispose();
          _isAppOpenAdReady = false;
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('❌ App Open Ad failed to show: ${error.message}');
          ad.dispose();
          _isAppOpenAdReady = false;
        },
      );
      await _appOpenAd?.show();
    }
  }

  // -----------------------------------------------------------------
  // Native ad handling
  // -----------------------------------------------------------------
  void loadNativeAd({required Function(NativeAd) onAdLoaded}) {
    final nativeAd = NativeAd(
      adUnitId: AppConstants.nativeAdUnitId,
      factoryId: 'adFactoryExample',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('✅ Native Ad loaded');
          onAdLoaded(ad as NativeAd);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ Native Ad failed to load: ${error.message}');
          ad.dispose();
        },
      ),
    );
    nativeAd.load();
  }

  // -----------------------------------------------------------------
  // Record an ad view via the Cloudflare Workers backend.
  // -----------------------------------------------------------------
  Future<bool> recordAdView(String userId, String adType) async {
    try {
      final deviceId = await _deviceFingerprint.getDeviceFingerprint();
      final result = await _cloudflare.recordAdView(
        userId: userId,
        adType: adType,
        deviceId: deviceId,
      );
      final success = result['success'] ?? false;
      debugPrint(
        success
            ? '✅ Ad view recorded for $userId (type: $adType) via backend'
            : '⚠️ Ad view failed: ${result['error'] ?? 'unknown'}',
      );
      return success;
    } catch (e) {
      debugPrint('❌ Error recording ad view: $e');
      return false;
    }
  }

  // -----------------------------------------------------------------
  // Dispose all ad objects.
  // -----------------------------------------------------------------
  void disposeAllAds() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _rewardedInterstitialAd?.dispose();
    _appOpenAd?.dispose();
    debugPrint('✅ All ads disposed');
  }
}
