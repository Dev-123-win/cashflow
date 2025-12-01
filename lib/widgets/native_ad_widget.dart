import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';
import '../core/constants/dimensions.dart';
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
          borderRadius: BorderRadius.all(
            Radius.circular(AppDimensions.radiusM),
          ),
        ),
      );
    }

    return Container(
      height: 120, // Adjust based on native ad template
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AdWidget(ad: _nativeAd!),
    );
  }
}
