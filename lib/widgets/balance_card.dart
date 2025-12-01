import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/constants/dimensions.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final VoidCallback onWithdraw;
  final bool canWithdraw;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.onWithdraw,
    this.canWithdraw = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Balance',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppDimensions.space8),
          Text(
            '₹${balance.toStringAsFixed(2)}',
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppDimensions.space16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canWithdraw ? onWithdraw : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.4),
                disabledForegroundColor: AppColors.primary.withValues(
                  alpha: 0.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Withdraw'),
                  if (!canWithdraw)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Min ₹50',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.primary.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
