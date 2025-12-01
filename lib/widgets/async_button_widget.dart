import 'package:flutter/material.dart';

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
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text(widget.loadingMessage ?? 'Loading...'),
            ],
          ),
        ),
      );
    }

    if (widget.icon != null) {
      return SizedBox(
        height: 48,
        child: ElevatedButton.icon(
          onPressed: widget.disabled ? null : _handlePress,
          icon: Icon(widget.icon),
          label: Text(widget.label),
        ),
      );
    }

    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: widget.disabled ? null : _handlePress,
        child: Text(widget.label),
      ),
    );
  }
}
