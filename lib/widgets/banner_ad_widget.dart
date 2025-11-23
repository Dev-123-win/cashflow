import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/theme/app_theme.dart';

/// Widget to display AdMob Banner Ad
class BannerAdWidget extends StatefulWidget {
  final double height;

  const BannerAdWidget({super.key, this.height = 50.0});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId:
          'ca-app-pub-3940256099942544/6300978111', // Test banner ad unit ID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() => _isAdLoaded = true);
          debugPrint('✅ Banner Ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ Banner Ad failed to load: ${error.message}');
          ad.dispose();
          setState(() => _isAdLoaded = false);
        },
      ),
    );
    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded) {
      return SizedBox(height: widget.height);
    }

    return Container(
      alignment: Alignment.center,
      width: double.maxFinite,
      height: widget.height,
      color: AppTheme.surfaceColor,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

/// Widget to display AdMob Native Ad
class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({super.key});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  void _loadNativeAd() {
    _nativeAd = NativeAd(
      adUnitId:
          'ca-app-pub-3940256099942544/2247696110', // Test native ad unit ID
      factoryId: 'adFactoryExample',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          setState(() => _isAdLoaded = true);
          debugPrint('✅ Native Ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ Native Ad failed to load: ${error.message}');
          ad.dispose();
          setState(() => _isAdLoaded = false);
        },
      ),
    );
    _nativeAd?.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded) {
      return const SizedBox.shrink();
    }

    return Container(
      color: AppTheme.surfaceColor,
      padding: const EdgeInsets.all(8),
      height: 320,
      child: AdWidget(ad: _nativeAd!),
    );
  }
}
