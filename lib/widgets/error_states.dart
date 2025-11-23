import 'package:flutter/material.dart';

/// GLOBAL STATE WIDGETS: Reusable components for consistent UX across the app
///
/// These widgets provide:
/// - Consistent loading states with animations
/// - Error states with retry buttons
/// - Empty states with helpful icons and messages
/// - Responsive design for all screen sizes
///
/// This ensures users always know what's happening (loading/error/empty)
/// instead of blank screens or mysterious delays.

/// Shows a centered loading indicator with optional message
///
/// Use this when:
/// - Fetching data from Firestore
/// - Waiting for API response
/// - Processing user action
///
/// Example:
/// ```dart
/// if (isLoading) {
///   return LoadingStateWidget(message: 'Fetching your tasks...');
/// }
/// ```
class LoadingStateWidget extends StatelessWidget {
  final String? message;
  final bool showSpinner;

  const LoadingStateWidget({super.key, this.message, this.showSpinner = true})
    : super();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showSpinner) ...[
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
            ),
            const SizedBox(height: 16),
          ],
          if (message != null) ...[
            Text(
              message!,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shows an error state with retry button
///
/// Use this when:
/// - Network request fails
/// - Firestore query throws error
/// - User action fails
///
/// Example:
/// ```dart
/// if (error != null) {
///   return ErrorStateWidget(
///     title: 'Failed to load tasks',
///     message: error!,
///     onRetry: () => fetchTasks(),
///   );
/// }
/// ```
class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final String retryButtonText;
  final IconData icon;

  const ErrorStateWidget({
    super.key,
    required this.title,
    this.message,
    this.onRetry,
    this.retryButtonText = 'Try Again',
    this.icon = Icons.error_outline,
  }) : super();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6C5CE7),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  retryButtonText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shows an empty state when no data is available
///
/// Use this when:
/// - User has no tasks completed yet
/// - No games have been played
/// - Task list is empty
/// - Withdrawal history is empty
///
/// Example:
/// ```dart
/// if (tasks.isEmpty) {
///   return EmptyStateWidget(
///     title: 'No tasks yet',
///     message: 'Come back later for more tasks to complete.',
///     icon: Icons.assignment_outlined,
///     actionButton: ElevatedButton(
///       onPressed: () => _refreshTasks(),
///       child: Text('Refresh'),
///     ),
///   );
/// }
/// ```
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Widget? actionButton;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionButton,
  }) : super();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            if (actionButton != null) ...[
              const SizedBox(height: 24),
              actionButton!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Generic state builder widget that handles loading/error/empty/content states
///
/// This is a convenience widget that handles all four states automatically
///
/// Use this when you want to handle all states with one widget:
///
/// Example:
/// ```dart
/// StateBuilder<List<Task>>(
///   isLoading: isLoading,
///   error: error,
///   data: tasks,
///   onRetry: () => fetchTasks(),
///   emptyMessage: 'No tasks available',
///   builder: (context, tasks) {
///     return ListView.builder(
///       itemCount: tasks.length,
///       itemBuilder: (context, index) => TaskCard(task: tasks[index]),
///     );
///   },
/// )
/// ```
class StateBuilder<T> extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final T? data;
  final VoidCallback? onRetry;
  final String loadingMessage;
  final String emptyTitle;
  final String emptyMessage;
  final IconData emptyIcon;
  final Widget Function(BuildContext, T) builder;

  const StateBuilder({
    super.key,
    required this.isLoading,
    this.error,
    this.data,
    this.onRetry,
    this.loadingMessage = 'Loading...',
    this.emptyTitle = 'No data',
    this.emptyMessage = 'No data available at the moment',
    this.emptyIcon = Icons.inbox_outlined,
    required this.builder,
  }) : super();

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (isLoading) {
      return LoadingStateWidget(message: loadingMessage);
    }

    // Show error state
    if (error != null) {
      return ErrorStateWidget(
        title: 'Something went wrong',
        message: error,
        onRetry: onRetry,
      );
    }

    // Show empty state
    if (data == null || (data is List && (data as List).isEmpty)) {
      return EmptyStateWidget(
        title: emptyTitle,
        message: emptyMessage,
        icon: emptyIcon,
      );
    }

    // Show content
    return builder(context, data as T);
  }
}

/// Snackbar helper for showing quick messages
///
/// Use this instead of ScaffoldMessenger.of(context).showSnackBar() everywhere
///
/// Example:
/// ```dart
/// StateSnackbar.show(context, 'Withdrawal request submitted!');
/// StateSnackbar.showError(context, 'Failed to submit withdrawal');
/// StateSnackbar.showSuccess(context, 'Task completed!');
/// ```
class StateSnackbar {
  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange[600],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
