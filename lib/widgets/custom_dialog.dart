import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String? emoji;
  final Widget content;
  final List<Widget>? actions;
  final bool showCloseButton;

  const CustomDialog({
    super.key,
    required this.title,
    required this.content,
    this.emoji,
    this.actions,
    this.showCloseButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceColor,
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        side: BorderSide(color: AppTheme.surfaceVariant, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: AppTheme.space16),
            ],
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space16),
            content,
            if (actions != null) ...[
              const SizedBox(height: AppTheme.space24),
              Row(
                children: actions!.map((action) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: action == actions!.last ? 0 : AppTheme.space12,
                      ),
                      child: action,
                    ),
                  );
                }).toList(),
              ),
            ],
            if (showCloseButton && actions == null) ...[
              const SizedBox(height: AppTheme.space24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceVariant,
                    foregroundColor: AppTheme.textPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
