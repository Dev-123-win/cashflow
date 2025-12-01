import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../../core/theme/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../services/cloudflare_workers_service.dart';
import '../../services/device_fingerprint_service.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_dialog.dart';
import '../../widgets/shimmer_loading.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  late TextEditingController _upiController;
  late TextEditingController _amountController;
  final CloudflareWorkersService _api = CloudflareWorkersService();
  String? _deviceId;
  bool _isProcessing = false;
  double minWithdrawal = 5000.0; // 5000 Coins = ₹5

  @override
  void initState() {
    super.initState();
    _upiController = TextEditingController();
    _amountController = TextEditingController();
    _initializeDeviceId();
    _loadSavedUpi();
  }

  Future<void> _loadSavedUpi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUpi = prefs.getString('saved_upi_id');
      if (savedUpi != null && mounted) {
        setState(() {
          _upiController.text = savedUpi;
        });
      }
    } catch (e) {
      debugPrint('Error loading saved UPI: $e');
    }
  }

  Future<void> _initializeDeviceId() async {
    try {
      _deviceId = await DeviceFingerprintService().getDeviceFingerprint();
    } catch (e) {
      debugPrint('Error getting device ID: $e');
    }
  }

  @override
  void dispose() {
    _upiController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitWithdrawal() async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not logged in')));
      }
      return;
    }

    if (_upiController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your UPI ID')));
      return;
    }

    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter coins')));
      return;
    }

    final coins = double.tryParse(_amountController.text) ?? 0;
    if (coins < minWithdrawal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimum withdrawal is ${minWithdrawal.toInt()} Coins'),
        ),
      );
      return;
    }

    final userProvider = context.read<UserProvider>();

    if (coins > userProvider.user.coins) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient coin balance')),
      );
      return;
    }

    if (_deviceId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Getting device info...')));
      return;
    }

    // Check backend health before proceeding
    final isBackendHealthy = await _api.healthCheck();
    if (!isBackendHealthy) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => CustomDialog(
            title: 'Connection Error',
            emoji: '⚠️',
            content: const Text(
              'Cannot connect to server. Please check your internet connection and try again.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    setState(() => _isProcessing = true);

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const CustomDialog(
          title: 'Processing',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Processing withdrawal request...'),
            ],
          ),
        ),
      );
    }

    try {
      // Generate request ID if not exists (or regenerate if needed, but here we keep it for retry logic if we implemented it)
      // For now, generate new one for each submit attempt to avoid 409 if previous one failed before reaching backend?
      // Actually, if we want to support retry of SAME request, we should persist ID.
      // But here we just generate one.
      final requestId = 'withdrawal_${DateTime.now().millisecondsSinceEpoch}';

      // Request withdrawal via API
      final result = await _api.requestWithdrawal(
        userId: user.uid,
        coins: coins.toInt(),
        upiId: _upiController.text,
        deviceId: _deviceId!,
        requestId: requestId,
      );

      // Save UPI ID
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_upi_id', _upiController.text);

      final withdrawalId = result['withdrawalId'] as String? ?? 'pending';
      final fiatValue = coins / 1000;

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => CustomDialog(
            title: 'Withdrawal Requested!',
            emoji: '✅',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${coins.toInt()} Coins (₹${fiatValue.toStringAsFixed(2)}) will be transferred to your UPI in 24-48 hours',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.space8),
                Text(
                  'Request ID: $withdrawalId',
                  style: Theme.of(context).textTheme.labelSmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Great!'),
              ),
            ],
          ),
        );
      }

      _upiController.clear();
      _amountController.clear();
    } catch (e) {
      debugPrint('Error submitting withdrawal: $e');
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show error
      if (mounted) {
        String errorMessage = 'An error occurred';
        if (e.toString().contains('Please wait')) {
          errorMessage = 'Please wait 5 minutes between withdrawal requests';
        } else if (e.toString().contains('Insufficient balance')) {
          errorMessage = 'Insufficient balance';
        } else {
          errorMessage = e.toString().replaceAll('Exception:', '').trim();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Widget _buildFeeBreakdown(BuildContext context) {
    // Simplified fee breakdown for Coins
    final coins = double.tryParse(_amountController.text) ?? 0;
    final fiatValue = coins / 1000;

    // Assuming 5% fee on fiat value
    final feeFiat = fiatValue * 0.05;
    final netFiat = fiatValue - feeFiat;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _breakdownRow('Coins to Redeem', '${coins.toInt()}', bold: true),
            const SizedBox(height: AppDimensions.space8),
            _breakdownRow('Fiat Value', '₹${fiatValue.toStringAsFixed(2)}'),
            const SizedBox(height: AppDimensions.space8),
            _breakdownRow(
              'Processing Fee (5%)',
              '-₹${feeFiat.toStringAsFixed(2)}',
              color: Colors.red,
            ),
            const Divider(height: 16),
            _breakdownRow(
              'You Will Receive',
              '₹${netFiat.toStringAsFixed(2)}',
              bold: true,
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _breakdownRow(
    String label,
    String value, {
    Color? color,
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
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
    final tertiaryColor = AppColors.info;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Redeem Coins'), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Card
              Consumer<UserProvider>(
                builder: (context, userProvider, _) {
                  if (userProvider.isLoading) {
                    return const ShimmerLoading.rectangular(
                      height: 180,
                      shapeBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(AppDimensions.radiusL),
                        ),
                      ),
                    );
                  }

                  final currentCoins = userProvider.user.coins;
                  final cashValue = currentCoins / 1000;
                  return Container(
                    padding: const EdgeInsets.all(AppDimensions.space24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor,
                          primaryColor.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusL,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Balance',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space8),
                        Row(
                          children: [
                            Image.asset(
                              'assets/icons/Coin.png',
                              width: 32,
                              height: 32,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$currentCoins Coins',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '≈ ₹${cashValue.toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.space12,
                            vertical: AppDimensions.space8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusS,
                            ),
                          ),
                          child: Text(
                            'Min withdrawal: ${minWithdrawal.toInt()} Coins',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: AppDimensions.space32),

              // Withdrawal Form
              Text('Enter Details', style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppDimensions.space16),

              // UPI ID Field
              Text(
                'UPI ID',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppDimensions.space8),
              Container(
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
                child: TextField(
                  controller: _upiController,
                  decoration: InputDecoration(
                    hintText: 'yourname@upi',
                    prefixIcon: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: primaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusM,
                      ),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: surfaceColor,
                    contentPadding: const EdgeInsets.all(AppDimensions.space16),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              const SizedBox(height: AppDimensions.space24),

              // Amount Field
              Text(
                'Coins to Withdraw',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppDimensions.space8),
              Container(
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
                child: TextField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    hintText: 'Enter Coins',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Image.asset(
                        'assets/icons/Coin.png',
                        width: 24,
                        height: 24,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusM,
                      ),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: surfaceColor,
                    contentPadding: const EdgeInsets.all(AppDimensions.space16),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: AppDimensions.space12),

              // Fee Breakdown (if amount entered)
              if (_amountController.text.isNotEmpty)
                _buildFeeBreakdown(context),

              if (_amountController.text.isNotEmpty)
                const SizedBox(height: AppDimensions.space24)
              else
                const SizedBox(height: AppDimensions.space12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Quick amount:', style: theme.textTheme.bodyMedium),
                  Consumer<UserProvider>(
                    builder: (context, userProvider, _) {
                      final currentCoins = userProvider.user.coins;
                      return Wrap(
                        spacing: AppDimensions.space8,
                        children: [5000, 10000, 25000].map((amount) {
                          final canUse = amount <= currentCoins;
                          return GestureDetector(
                            onTap: canUse
                                ? () {
                                    HapticFeedback.lightImpact();
                                    _amountController.text = amount.toString();
                                    setState(() {});
                                  }
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.space16,
                                vertical: AppDimensions.space8,
                              ),
                              decoration: BoxDecoration(
                                color: canUse
                                    ? primaryColor.withValues(alpha: 0.1)
                                    : surfaceVariant,
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusM,
                                ),
                                border: canUse
                                    ? Border.all(
                                        color: primaryColor.withValues(
                                          alpha: 0.3,
                                        ),
                                      )
                                    : null,
                              ),
                              child: Opacity(
                                opacity: canUse ? 1.0 : 0.5,
                                child: Text(
                                  '$amount',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: canUse
                                        ? primaryColor
                                        : textSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space32),

              // Info Box
              Container(
                padding: const EdgeInsets.all(AppDimensions.space16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  border: Border.all(
                    color: tertiaryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: tertiaryColor.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: tertiaryColor,
                        ),
                        const SizedBox(width: AppDimensions.space12),
                        Expanded(
                          child: Text(
                            'Processing Time',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space8),
                    Text(
                      'Withdrawals are processed within 24-48 hours. You will receive a notification once your money is transferred.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.space32),

              // Submit Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _submitWithdrawal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusL,
                      ),
                    ),
                    elevation: 0,
                  ),
                  child: _isProcessing
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Processing...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Request Withdrawal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppDimensions.space32),
            ],
          ),
        ),
      ),
    );
  }
}
