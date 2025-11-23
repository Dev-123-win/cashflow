import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

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
      padding: const EdgeInsets.all(AppTheme.space24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.elevatedShadow,
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
          const SizedBox(height: AppTheme.space8),
          Text(
            '₹${balance.toStringAsFixed(2)}',
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppTheme.space16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canWithdraw ? onWithdraw : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Withdraw'),
            ),
          ),
        ],
      ),
    );
  }
}
