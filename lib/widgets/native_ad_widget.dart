import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';
import '../core/theme/app_theme.dart';
import 'shimmer_loading.dart';

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
    _loadAd();
  }

  void _loadAd() {
    AdService().loadNativeAd(
      onAdLoaded: (ad) {
        if (mounted) {
          setState(() {
            _nativeAd = ad;
            _isAdLoaded = true;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded) {
      return const ShimmerLoading.rectangular(
        height: 100,
        shapeBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppTheme.radiusM)),
        ),
      );
    }

    return Container(
      height: 120, // Adjust based on native ad template
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: AppTheme.softShadow,
      ),
      child: AdWidget(ad: _nativeAd!),
    );
  }
}
