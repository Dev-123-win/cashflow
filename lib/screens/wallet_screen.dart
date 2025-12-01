import 'package:flutter/material.dart';
import 'withdrawal/withdrawal_screen.dart';
import 'transaction_history_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Wallet'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          labelColor: primaryColor,
          unselectedLabelColor: onSurfaceVariant,
          tabs: const [
            Tab(
              text: 'Withdraw',
              icon: Icon(Icons.account_balance_wallet_outlined),
            ),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [WithdrawalScreen(), TransactionHistoryScreen()],
      ),
    );
  }
}
