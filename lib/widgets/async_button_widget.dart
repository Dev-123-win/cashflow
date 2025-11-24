import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Async button that prevents double-taps and shows loading state
class AsyncElevatedButton extends StatefulWidget {
  final String label;
  final Future<void> Function() onPressed;
  final VoidCallback? onSuccess;
  final Function(String error)? onError;
  final bool disabled;
  final IconData? icon;
  final double? minWidth;
  final String? loadingMessage;

  const AsyncElevatedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.onSuccess,
    this.onError,
    this.disabled = false,
    this.icon,
    this.minWidth,
    this.loadingMessage,
  });

  @override
  State<AsyncElevatedButton> createState() => _AsyncElevatedButtonState();
}

class _AsyncElevatedButtonState extends State<AsyncElevatedButton> {
  bool _isLoading = false;

  Future<void> _handlePress() async {
    if (_isLoading || widget.disabled) return;

    setState(() => _isLoading = true);

    try {
      await widget.onPressed();
      widget.onSuccess?.call();
    } catch (e) {
      widget.onError?.call(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: 48,
        child: ElevatedButton(
          onPressed: null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Text(widget.loadingMessage ?? 'Processing...'),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: widget.minWidth,
      height: 48,
      child: widget.icon != null
          ? ElevatedButton.icon(
              onPressed: widget.disabled ? null : _handlePress,
              icon: Icon(widget.icon),
              label: Text(widget.label),
            )
          : ElevatedButton(
              onPressed: widget.disabled ? null : _handlePress,
              child: Text(widget.label),
            ),
    );
  }
}

/// Async text button (flat button style)
class AsyncTextButton extends StatefulWidget {
  final String label;
  final Future<void> Function() onPressed;
  final VoidCallback? onSuccess;
  final Function(String error)? onError;
  final bool disabled;
  final IconData? icon;

  const AsyncTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.onSuccess,
    this.onError,
    this.disabled = false,
    this.icon,
  });

  @override
  State<AsyncTextButton> createState() => _AsyncTextButtonState();
}

class _AsyncTextButtonState extends State<AsyncTextButton> {
  bool _isLoading = false;

  Future<void> _handlePress() async {
    if (_isLoading || widget.disabled) return;

    setState(() => _isLoading = true);

    try {
      await widget.onPressed();
      widget.onSuccess?.call();
    } catch (e) {
      widget.onError?.call(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      );
    }

    return widget.icon != null
        ? TextButton.icon(
            onPressed: widget.disabled ? null : _handlePress,
            icon: Icon(widget.icon),
            label: Text(widget.label),
          )
        : TextButton(
            onPressed: widget.disabled ? null : _handlePress,
            child: Text(widget.label),
          );
  }
}
