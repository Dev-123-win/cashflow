import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import '../core/theme/app_theme.dart';

class ParallaxBalanceCard extends StatefulWidget {
  final double balance;
  final VoidCallback onWithdraw;
  final bool canWithdraw;

  const ParallaxBalanceCard({
    super.key,
    required this.balance,
    required this.onWithdraw,
    required this.canWithdraw,
  });

  @override
  State<ParallaxBalanceCard> createState() => _ParallaxBalanceCardState();
}

class _ParallaxBalanceCardState extends State<ParallaxBalanceCard> {
  double _x = 0;
  double _y = 0;
  StreamSubscription<AccelerometerEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = accelerometerEventStream().listen((
      AccelerometerEvent event,
    ) {
      if (mounted) {
        setState(() {
          _x = event.x;
          _y = event.y;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C63FF), Color(0xFF4834D4)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Parallax Glare
          AnimatedPositioned(
            duration: const Duration(milliseconds: 100),
            top: -50 + (_y * 5),
            left: -50 + (_x * 5),
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(AppTheme.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Balance',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                        ),
                        const SizedBox(height: AppTheme.space8),
                        Text(
                          '₹${widget.balance.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontFeatures: [
                                  const FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.space8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.canWithdraw ? widget.onWithdraw : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.space12,
                      ),
                    ),
                    child: const Text('Withdraw Funds'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
