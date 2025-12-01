import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme/colors.dart';
import '../core/constants/dimensions.dart';
import '../services/transaction_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/constants/app_assets.dart';
import '../providers/user_provider.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late final TransactionService _transactionService;
  String _selectedFilter = 'all'; // all, earning, withdrawal
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _transactionService = TransactionService();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserProvider>().user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primary;
    final secondaryColor = isDark ? AppColors.accentDark : AppColors.accent;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Transaction History'),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            color: theme.scaffoldBackgroundColor,
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        value: 'all',
                        selectedValue: _selectedFilter,
                        onTap: () => setState(() => _selectedFilter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Earnings',
                        value: 'earning',
                        selectedValue: _selectedFilter,
                        onTap: () =>
                            setState(() => _selectedFilter = 'earning'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Withdrawals',
                        value: 'withdrawal',
                        selectedValue: _selectedFilter,
                        onTap: () =>
                            setState(() => _selectedFilter = 'withdrawal'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _selectDate(context, isStartDate: true),
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          _startDate == null
                              ? 'From Date'
                              : DateFormat('MMM d').format(_startDate!),
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _selectDate(context, isStartDate: false),
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          _endDate == null
                              ? 'To Date'
                              : DateFormat('MMM d').format(_endDate!),
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (_startDate != null || _endDate != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => setState(() {
                          _startDate = null;
                          _endDate = null;
                        }),
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        tooltip: 'Clear dates',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Transaction List
          Expanded(
            child: StreamBuilder<List<TransactionModel>>(
              stream: _getTransactionStream(currentUser.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          AppAssets.emptyHistory,
                          height: 200,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final transactions = snapshot.data!;
                double totalIncome = transactions
                    .where((t) => t.type == 'earning')
                    .fold(0, (sum, t) => sum + t.amount);
                double totalWithdrawal = transactions
                    .where((t) => t.type == 'withdrawal')
                    .fold(0, (sum, t) => sum + t.amount);

                return ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  children: [
                    // Summary Card
                    if (_selectedFilter == 'all')
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, secondaryColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusXL,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Earnings',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${totalIncome.toInt()} Coins',
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white24,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Withdrawn',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${totalWithdrawal.toInt()} Coins',
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Transaction List
                    ...transactions.map(
                      (transaction) =>
                          _TransactionCard(transaction: transaction),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<TransactionModel>> _getTransactionStream(String userId) {
    if (_selectedFilter == 'all') {
      return _transactionService.getUserTransactions(
        userId,
        startDate: _startDate,
        endDate: _endDate,
        limit: 100,
      );
    } else {
      return _transactionService.getUserTransactions(
        userId,
        filterType: _selectedFilter,
        startDate: _startDate,
        endDate: _endDate,
        limit: 100,
      );
    }
  }

  Future<void> _selectDate(
    BuildContext context, {
    required bool isStartDate,
  }) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primary;

    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String selectedValue;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selectedValue;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primary;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionCard({required this.transaction});

  String _getTransactionIcon() {
    if (transaction.type == 'earning') {
      switch (transaction.gameType) {
        case 'tictactoe':
          return '❌';
        case 'memory_match':
          return '🎴';
        case 'quiz':
          return '🧠';
        case 'spin':
          return '🎡';
        case 'task':
          return '📋';
        case 'ad':
          return '📺';
        default:
          return '💰';
      }
    } else if (transaction.type == 'withdrawal') {
      return '🏦';
    } else if (transaction.type == 'refund') {
      return '↩️';
    }
    return '💳';
  }

  Color _getIconBgColor() {
    if (transaction.type == 'earning') {
      return Colors.green.shade50;
    } else if (transaction.type == 'withdrawal') {
      return Colors.orange.shade50;
    }
    return Colors.grey.shade50;
  }

  String _getTransactionLabel() {
    if (transaction.type == 'earning') {
      switch (transaction.gameType) {
        case 'tictactoe':
          return 'Tic-Tac-Toe Win';
        case 'memory_match':
          return 'Memory Match Win';
        case 'quiz':
          return 'Quiz Reward';
        case 'spin':
          return 'Daily Spin';
        case 'task':
          return 'Task Completed';
        case 'ad':
          return 'Ad Reward';
        default:
          return 'Earning';
      }
    } else if (transaction.type == 'withdrawal') {
      return 'Withdrawal Request';
    } else if (transaction.type == 'refund') {
      return 'Refund';
    }
    return 'Transaction';
  }

  Color _getStatusColor() {
    if (transaction.status == 'completed') {
      return AppColors.success;
    } else if (transaction.status == 'pending') {
      return AppColors.warning;
    } else {
      return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final surfaceVariant = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariantLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: surfaceVariant, width: 1),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getIconBgColor(),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _getTransactionIcon(),
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTransactionLabel(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, h:mm a').format(transaction.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          // Amount & Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${transaction.type == 'earning' ? '+' : '-'}${transaction.amount.toInt()} Coins',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: transaction.type == 'earning'
                      ? AppColors.success
                      : AppColors.error,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  transaction.status.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
