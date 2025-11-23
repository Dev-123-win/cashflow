import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class AdService {
  static final AdService _instance = AdService._internal();

  factory AdService() {
    return _instance;
  }

  AdService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('✅ Google Mobile Ads initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize Google Mobile Ads: $e');
    }
  }

  // Banner Ad
  BannerAd? _bannerAd;

  void createBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AppConstants.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('✅ Banner Ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ Banner Ad failed to load: ${error.message}');
          ad.dispose();
        },
      ),
    );
    _bannerAd?.load();
  }

  BannerAd? getBannerAd() => _bannerAd;

  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  // Interstitial Ad
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
        onAdShowedFullScreenContent: (ad) {
          debugPrint('✅ Interstitial Ad showed');
        },
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('✅ Interstitial Ad dismissed');
          ad.dispose();
          _isInterstitialAdReady = false;
          loadInterstitialAd(); // Preload next ad
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

  // Rewarded Ad
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
        onAdShowedFullScreenContent: (ad) {
          debugPrint('✅ Rewarded Ad showed');
        },
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('✅ Rewarded Ad dismissed');
          ad.dispose();
          _isRewardedAdReady = false;
          loadRewardedAd(); // Preload next ad
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('❌ Rewarded Ad failed to show: ${error.message}');
          ad.dispose();
          _isRewardedAdReady = false;
        },
      );

      await _rewardedAd?.show(
        onUserEarnedReward: (ad, reward) {
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

  // Rewarded Interstitial Ad
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
              '❌ Rewarded Interstitial Ad failed to load: ${error.message}');
        },
      ),
    );
  }

  Future<bool> showRewardedInterstitialAd(
      {required Function(int) onRewardEarned}) async {
    if (_isRewardedInterstitialAdReady) {
      _rewardedInterstitialAd?.fullScreenContentCallback =
          FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          debugPrint('✅ Rewarded Interstitial Ad showed');
        },
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('✅ Rewarded Interstitial Ad dismissed');
          ad.dispose();
          _isRewardedInterstitialAdReady = false;
          loadRewardedInterstitialAd(); // Preload next ad
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint(
              '❌ Rewarded Interstitial Ad failed to show: ${error.message}');
          ad.dispose();
          _isRewardedInterstitialAdReady = false;
        },
      );

      await _rewardedInterstitialAd?.show(
        onUserEarnedReward: (ad, reward) {
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

  // App Open Ad
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
        onAdShowedFullScreenContent: (ad) {
          debugPrint('✅ App Open Ad showed');
        },
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

  // Native Ad
  void loadNativeAd({required Function(NativeAd) onAdLoaded}) {
    final NativeAd nativeAd = NativeAd(
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

  // Dispose all ads
  void disposeAllAds() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _rewardedInterstitialAd?.dispose();
    _appOpenAd?.dispose();

    _bannerAd = null;
    _interstitialAd = null;
    _rewardedAd = null;
    _rewardedInterstitialAd = null;
    _appOpenAd = null;

    _isRewardedAdReady = false;
    _isInterstitialAdReady = false;
    _isRewardedInterstitialAdReady = false;
    _isAppOpenAdReady = false;

    debugPrint('✅ All ads disposed');
  }
}
