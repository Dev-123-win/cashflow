import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../../core/theme/app_theme.dart';
import '../../core/utils/device_utils.dart';
import '../../services/cloudflare_workers_service.dart';
import '../../services/fee_calculation_service.dart';
import '../../providers/user_provider.dart';
import '../../widgets/error_states.dart';
import '../../widgets/custom_dialog.dart';

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
  double minWithdrawal = 50.0;

  @override
  void initState() {
    super.initState();
    _upiController = TextEditingController();
    _amountController = TextEditingController();
    _initializeDeviceId();
  }

  Future<void> _initializeDeviceId() async {
    try {
      _deviceId = await DeviceUtils.getDeviceId();
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
      ).showSnackBar(const SnackBar(content: Text('Please enter amount')));
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount < minWithdrawal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Minimum withdrawal amount is ₹${minWithdrawal.toStringAsFixed(2)}',
          ),
        ),
      );
      return;
    }

    final userProvider = context.read<UserProvider>();
    if (amount > userProvider.user.availableBalance) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Insufficient balance')));
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
      // Request withdrawal via API
      final result = await _api.requestWithdrawal(
        userId: user.uid,
        amount: amount,
        upiId: _upiController.text,
        deviceId: _deviceId!,
      );

      final withdrawalId = result['withdrawalId'] as String? ?? 'pending';

      // Deduct balance from user
      if (mounted) {
        // Balance update is handled by backend and reflected via UserProvider stream
      }

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
                  '₹${amount.toStringAsFixed(2)} will be transferred to your UPI in 24-48 hours',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.space8),
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
    final feeService = Provider.of<FeeCalculationService>(
      context,
      listen: false,
    );
    final amount = double.tryParse(_amountController.text) ?? 0;
    final breakdown = feeService.getFeeBreakdown(amount);

    // Validate amount
    final (isValid, error) = feeService.validateWithdrawalAmount(amount);

    if (!isValid) {
      return ErrorStateWidget(
        title: 'Invalid Amount',
        message: error,
        icon: Icons.warning_amber,
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _breakdownRow(
              'Amount Requested',
              breakdown['grossAmount']!,
              bold: true,
            ),
            const SizedBox(height: AppTheme.space8),
            _breakdownRow(
              'Withdrawal Fee (5%)',
              breakdown['fee']!,
              color: Colors.red,
            ),
            const Divider(height: 16),
            _breakdownRow(
              'You Will Receive',
              breakdown['netAmount']!,
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Withdraw Earnings'), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Card
              Consumer<UserProvider>(
                builder: (context, userProvider, _) {
                  final currentBalance = userProvider.user.availableBalance;
                  return Container(
                    padding: const EdgeInsets.all(AppTheme.space24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      boxShadow: AppTheme.elevatedShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Balance',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: AppTheme.space8),
                        Text(
                          '₹${currentBalance.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: AppTheme.space16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.space12,
                            vertical: AppTheme.space8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusS,
                            ),
                          ),
                          child: Text(
                            'Min withdrawal: ₹${minWithdrawal.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: AppTheme.space32),

              // Withdrawal Form
              Text(
                'Enter Details',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppTheme.space16),

              // UPI ID Field
              Text('UPI ID', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppTheme.space8),
              TextField(
                controller: _upiController,
                decoration: InputDecoration(
                  hintText: 'yourname@upi',
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppTheme.space24),

              // Amount Field
              Text('Amount', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppTheme.space8),
              TextField(
                controller: _amountController,
                decoration: InputDecoration(
                  hintText: 'Enter amount',
                  prefixIcon: const Icon(Icons.currency_rupee),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppTheme.space12),

              // Fee Breakdown (if amount entered)
              if (_amountController.text.isNotEmpty)
                _buildFeeBreakdown(context),

              if (_amountController.text.isNotEmpty)
                const SizedBox(height: AppTheme.space24)
              else
                const SizedBox(height: AppTheme.space12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick amount:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Consumer<UserProvider>(
                    builder: (context, userProvider, _) {
                      final balance = userProvider.user.availableBalance;
                      return Wrap(
                        spacing: AppTheme.space8,
                        children: [50.0, 100.0, 150.0].map((amount) {
                          final canUse = amount <= balance;
                          return GestureDetector(
                            onTap: canUse
                                ? () {
                                    _amountController.text = amount
                                        .toStringAsFixed(0);
                                    setState(() {});
                                  }
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.space12,
                                vertical: AppTheme.space8,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusS,
                                ),
                                boxShadow: AppTheme.cardShadow,
                              ),
                              child: Opacity(
                                opacity: canUse ? 1.0 : 0.5,
                                child: Text(
                                  '₹${amount.toStringAsFixed(0)}',
                                  style: Theme.of(context).textTheme.labelLarge,
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
              const SizedBox(height: AppTheme.space32),

              // Info Box
              Container(
                padding: const EdgeInsets.all(AppTheme.space12),
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
                            'Processing Time',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      'Withdrawals are processed within 24-48 hours. You will receive a notification once your money is transferred.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _submitWithdrawal,
                  child: _isProcessing
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Processing...'),
                          ],
                        )
                      : const Text('Request Withdrawal'),
                ),
              ),
              const SizedBox(height: AppTheme.space32),
            ],
          ),
        ),
      ),
    );
  }
}
