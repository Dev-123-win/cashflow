import 'package:intl/intl.dart';

class AppUtils {
  // Format currency with Indian Rupee symbol
  static String formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  // Format date and time
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  // Format date only
  static String formatDate(DateTime dateTime) {
    return DateFormat('dd MMM yyyy').format(dateTime);
  }

  // Format time only
  static String formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  // Get time difference
  static String getTimeDifference(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return formatDate(dateTime);
    }
  }

  // Check if two dates are same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Get day of week name
  static String getDayName(DateTime dateTime) {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[dateTime.weekday - 1];
  }

  // Get color based on status
  static String getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return '⏳ Pending';
      case 'completed':
        return '✅ Completed';
      case 'failed':
        return '❌ Failed';
      case 'processing':
        return '⏸️ Processing';
      default:
        return status;
    }
  }

  // Validate email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // Validate UPI ID
  static bool isValidUPI(String upi) {
    final upiRegex = RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z]{3,}$');
    return upiRegex.hasMatch(upi);
  }

  // Generate random string
  static String generateRandomString(int length) {
    const charset =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().microsecond;
    final buffer = StringBuffer();

    for (int i = 0; i < length; i++) {
      buffer.write(charset[(random + i) % charset.length]);
    }

    return buffer.toString();
  }

  // Get greeting message
  static String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else if (hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  // Format percentage
  static String formatPercentage(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }

  // Calculate percentage
  static double calculatePercentage(double current, double max) {
    if (max == 0) return 0;
    return (current / max).clamp(0, 1);
  }

  // Format large numbers
  static String formatLargeNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  // Get device ID (mock implementation)
  static String getDeviceId() {
    // In a real app, use device_info_plus to get actual device ID
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Debounce function
  static Future<void> debounce(Duration duration, Function() callback) async {
    await Future.delayed(duration);
    callback();
  }

  // Show snackbar message
  static void showMessage(
    dynamic context,
    String message, {
    int durationSeconds = 2,
    bool isError = false,
  }) {
    // Implementation depends on context type
    // This is a placeholder
  }
}
