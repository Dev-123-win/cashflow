import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../../core/theme/app_theme.dart';
import '../../services/referral_service.dart';

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

  final List<ReferredUser> _referredUsers = [];

  void _copyReferralCode() {
    Clipboard.setData(ClipboardData(text: _referralCode));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Referral code copied!')));
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
      // Generate or get referral code
      final code = await _referralService.generateReferralCode(_currentUserId);

      // Get referral stats
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: const Text('Invite Friends'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withValues(alpha: 0.1),
                          AppTheme.primaryColor.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '─── How It Works ───',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: AppTheme.space16),
                        _buildStep(context, '1️⃣', 'Share your code'),
                        _buildStep(
                          context,
                          '2️⃣',
                          'Friend signs up & earns ₹10',
                        ),
                        _buildStep(context, '3️⃣', 'You get ₹2!'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.space32),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space24),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Your Referral Code',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: AppTheme.space16),
                        Container(
                          padding: const EdgeInsets.all(AppTheme.space16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusS,
                            ),
                            border: Border.all(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Text(
                            _referralCode,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _copyReferralCode,
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy Code'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.space24),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat(
                          context,
                          '$_totalReferred',
                          'Total Referred',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppTheme.surfaceVariant,
                        ),
                        _buildStat(
                          context,
                          '₹${_earnedFromReferrals.toStringAsFixed(2)}',
                          'Earned',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.space32),
                  Text(
                    'Your Referrals',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppTheme.space16),
                  ..._referredUsers.map((user) => _buildReferralCard(user)),
                ],
              ),
            ),
    );
  }

  Widget _buildStep(BuildContext context, String icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space12),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: AppTheme.space12),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildReferralCard(ReferredUser user) {
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
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
            child: Text(user.name[0]),
          ),
          const SizedBox(width: AppTheme.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(
                  'Earned you ₹${user.earnedForYou.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space8,
              vertical: AppTheme.space4,
            ),
            decoration: BoxDecoration(
              color: user.status == 'Completed'
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: Text(
              user.status,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: user.status == 'Completed'
                    ? Colors.green
                    : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
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
