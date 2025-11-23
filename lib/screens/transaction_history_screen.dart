import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../services/transaction_service.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _selectDate(context, isStartDate: true),
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _startDate == null
                              ? 'From Date'
                              : 'From: ${_startDate!.toString().split(' ')[0]}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _selectDate(context, isStartDate: false),
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _endDate == null
                              ? 'To Date'
                              : 'To: ${_endDate!.toString().split(' ')[0]}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => setState(() {
                        _startDate = null;
                        _endDate = null;
                      }),
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                    ),
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
                        const Icon(
                          Icons.history_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions yet',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final transactions = snapshot.data!;
                double totalAmount = 0;
                for (var transaction in transactions) {
                  if (transaction.type == 'earning') {
                    totalAmount += transaction.amount;
                  } else if (transaction.type == 'withdrawal') {
                    totalAmount -= transaction.amount;
                  }
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  children: [
                    // Summary Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text(
                                    'Transactions',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${transactions.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text(
                                    'Earnings',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${transactions.where((t) => t.type == 'earning').fold<double>(0, (sum, t) => sum + t.amount).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text(
                                    'Withdrawn',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${transactions.where((t) => t.type == 'withdrawal').fold<double>(0, (sum, t) => sum + t.amount).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
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
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.transparent,
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.3),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : Colors.grey,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
        width: isSelected ? 2 : 1,
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
          return '❌⭕';
        case 'memory_match':
          return '🎴';
        case 'quiz':
          return '🧠';
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

  String _getTransactionLabel() {
    if (transaction.type == 'earning') {
      switch (transaction.gameType) {
        case 'tictactoe':
          return 'Tic-Tac-Toe';
        case 'memory_match':
          return 'Memory Match';
        case 'quiz':
          return 'Daily Quiz';
        default:
          return 'Game Earning';
      }
    } else if (transaction.type == 'withdrawal') {
      return 'Withdrawal';
    } else if (transaction.type == 'refund') {
      return 'Refund';
    }
    return 'Transaction';
  }

  Color _getStatusColor() {
    if (transaction.status == 'completed') {
      return Colors.green;
    } else if (transaction.status == 'pending') {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getTransactionIcon(),
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTransactionLabel(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      transaction.timestamp.toString().split('.')[0],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        transaction.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: _getStatusColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${transaction.type == 'earning' ? '+' : '-'}₹${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: transaction.type == 'earning'
                      ? Colors.green
                      : Colors.red,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                transaction.type == 'earning' ? 'Earned' : 'Withdrawn',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
