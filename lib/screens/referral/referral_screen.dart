import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:share_plus/share_plus.dart';
import '../../core/theme/colors.dart';

import '../../services/referral_service.dart';
import '../../widgets/zen_card.dart';
import '../../widgets/scale_button.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  late ReferralService _referralService;
  late String _currentUserId;
  String _referralCode = '';
  int _totalReferred = 0;
  double _earnedFromReferrals = 0.0;
  bool _isLoading = true;

  void _copyReferralCode() {
    Clipboard.setData(ClipboardData(text: _referralCode));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Referral code copied!')));
  }

  void _shareReferralCode() {
    Share.share(
      'Join CashFlow and earn real money! Use my referral code: $_referralCode to get a bonus! Download now: [Link]',
    );
  }

  @override
  void initState() {
    super.initState();
    _referralService = ReferralService();
    _currentUserId = fb_auth.FirebaseAuth.instance.currentUser?.uid ?? '';
    _loadReferralData();
  }

  Future<void> _loadReferralData() async {
    try {
      final code = await _referralService.generateReferralCode(_currentUserId);
      final stats = await _referralService.getReferralStats(_currentUserId);

      setState(() {
        _referralCode = code;
        _totalReferred = stats.totalReferrals;
        _earnedFromReferrals = stats.totalEarningsFromReferrals;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading referral data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primary;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Invite & Earn'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.card_giftcard,
                          size: 80,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Refer Friends, Earn Money',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Get ₹2 for every friend who joins!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Total Referred',
                                '$_totalReferred',
                                Icons.people_outline,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                'Total Earned',
                                '₹${_earnedFromReferrals.toStringAsFixed(0)}',
                                Icons.monetization_on_outlined,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Referral Code Section
                        Text(
                          'Your Referral Code',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ZenCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Share this code',
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _referralCode,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  ScaleButton(
                                    onTap: _copyReferralCode,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.copy,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                  ScaleButton(
                                    onTap: _shareReferralCode,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.share,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // How it works
                        Text(
                          'How it works',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStep(
                          '1',
                          'Share your code',
                          'Share your unique referral code with friends via WhatsApp, Telegram, etc.',
                        ),
                        _buildStep(
                          '2',
                          'Friend signs up',
                          'Your friend downloads the app and enters your code during signup.',
                        ),
                        _buildStep(
                          '3',
                          'You both earn',
                          'You get ₹2 instantly, and your friend gets a ₹10 welcome bonus!',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return ZenCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStep(
    String number,
    String title,
    String description, {
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primary;
    final surfaceVariant = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariantLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: surfaceVariant,
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(color: textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

class ReferredUser {
  final String name;
  final double earnedForYou;
  final DateTime date;
  final String status;

  ReferredUser({
    required this.name,
    required this.earnedForYou,
    required this.date,
    required this.status,
  });
}
