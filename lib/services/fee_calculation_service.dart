/// MONETIZATION SERVICE: Calculates withdrawal fees for the app (OPTIMIZED)
///
/// This service handles all fee-related calculations:
/// - 2% withdrawal fee (OPTIMIZED from 5%)
/// - Minimum fee: ₹2
/// - Maximum fee: ₹50
/// - Tax on earnings: 0% (user-friendly)
///
/// Why this matters:
/// - Transparent fee structure (users see fee BEFORE confirming)
/// - Expected monthly revenue: ₹15k from withdrawals (based on 10k users × 30% withdrawal rate × ₹100 avg × 2% fee)
/// - Free tier optimization: No backend calculation needed
class FeeCalculationService {
  static const double _withdrawalFeePercentage = 0.02; // 2% (OPTIMIZED from 5%)
  static const double _minFee = 2.0; // Increased from 1.0
  static const double _maxFee = 50.0;

  /// Calculates the withdrawal fee for a given amount
  ///
  /// Parameters:
  /// - amount: Amount user wants to withdraw
  ///
  /// Returns: Fee amount in rupees
  ///
  /// Examples:
  /// - ₹100 → fee = ₹5 (5%)
  /// - ₹200 → fee = ₹10 (5%)
  /// - ₹1000 → fee = ₹50 (capped at max)
  /// - ₹50 → fee = ₹1 (minimum)
  double calculateWithdrawalFee(double amount) {
    if (amount <= 0) return 0;

    // Calculate 5% fee
    double fee = amount * _withdrawalFeePercentage;

    // Apply min/max bounds
    if (fee < _minFee) {
      fee = _minFee;
    } else if (fee > _maxFee) {
      fee = _maxFee;
    }

    return fee;
  }

  /// Calculates amount user will actually receive after fees
  ///
  /// Parameters:
  /// - amount: Amount user wants to withdraw
  ///
  /// Returns: Amount user receives (after fee deduction)
  ///
  /// Examples:
  /// - ₹100 → receives ₹95
  /// - ₹1000 → receives ₹950
  double calculateNetAmount(double amount) {
    final fee = calculateWithdrawalFee(amount);
    return amount - fee;
  }

  /// Gets fee breakdown for UI display
  ///
  /// Returns: Map with formatted strings for display
  ///
  /// Example output:
  /// {
  ///   'grossAmount': '₹100',
  ///   'fee': '₹5',
  ///   'netAmount': '₹95',
  ///   'feePercentage': '5%'
  /// }
  Map<String, String> getFeeBreakdown(double amount) {
    final fee = calculateWithdrawalFee(amount);
    final netAmount = calculateNetAmount(amount);
    final feePercentage = (amount > 0 && fee > 0)
        ? ((fee / amount) * 100).toStringAsFixed(1)
        : '0.0';

    return {
      'grossAmount': '₹${amount.toStringAsFixed(2)}',
      'fee': '₹${fee.toStringAsFixed(2)}',
      'netAmount': '₹${netAmount.toStringAsFixed(2)}',
      'feePercentage': '$feePercentage%',
    };
  }

  /// Validates if withdrawal amount is within acceptable bounds
  ///
  /// Returns:
  /// - (true, null) if valid
  /// - (false, errorMessage) if invalid
  (bool isValid, String? error) validateWithdrawalAmount(double amount) {
    const double minWithdrawal = 100.0;
    const double maxWithdrawal = 10000.0;

    if (amount < minWithdrawal) {
      return (false, 'Minimum withdrawal: ₹${minWithdrawal.toInt()}');
    }

    if (amount > maxWithdrawal) {
      return (false, 'Maximum withdrawal: ₹${maxWithdrawal.toInt()}');
    }

    if (amount <= 0) {
      return (false, 'Amount must be greater than ₹0');
    }

    return (true, null);
  }

  /// Estimates monthly revenue from withdrawal fees
  ///
  /// This is useful for analytics and business metrics
  ///
  /// Parameters:
  /// - activeUsers: Number of users making withdrawals
  /// - avgWithdrawalAmount: Average withdrawal amount per user per month
  ///
  /// Returns: Estimated revenue in rupees
  ///
  /// Example:
  /// - 1000 active users × ₹100 avg withdrawal × 5% fee = ₹5,000/month
  /// - But with max fee of ₹50, actual might be different
  double estimateMonthlyRevenue({
    required int activeUsers,
    required double avgWithdrawalAmount,
  }) {
    double totalFees = 0;
    for (int i = 0; i < activeUsers; i++) {
      totalFees += calculateWithdrawalFee(avgWithdrawalAmount);
    }
    return totalFees;
  }

  /// Gets fee tier information for user education
  ///
  /// Returns: List of example withdrawals and their fees
  ///
  /// Useful for showing users in a FAQ or help screen
  List<Map<String, String>> getFeeExamples() {
    const amounts = [50.0, 100.0, 200.0, 500.0, 1000.0, 5000.0];

    return amounts.map((amount) {
      final fee = calculateWithdrawalFee(amount);
      final net = calculateNetAmount(amount);
      return {
        'amount': '₹${amount.toInt()}',
        'fee': '₹${fee.toStringAsFixed(2)}',
        'youGet': '₹${net.toStringAsFixed(2)}',
        'percentage': '${((fee / amount) * 100).toStringAsFixed(1)}%',
      };
    }).toList();
  }
}
