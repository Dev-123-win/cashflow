import 'package:flutter/material.dart';
import '../../core/constants/dimensions.dart';
import '../../core/theme/colors.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final AppButtonType type;
  final Color? backgroundColor;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.type = AppButtonType.primary,
    this.backgroundColor,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.backgroundColor,
  }) : type = AppButtonType.secondary;

  const AppButton.outline({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.backgroundColor,
  }) : type = AppButtonType.outline;

  const AppButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.backgroundColor,
  }) : type = AppButtonType.text;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _getLoadingColor(isLight),
            ),
          ),
          const SizedBox(width: AppDimensions.space12),
        ] else if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: AppDimensions.space8),
        ],
        Text(label),
      ],
    );

    Widget button;
    switch (type) {
      case AppButtonType.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: Size(
              isFullWidth ? double.infinity : 0,
              AppDimensions.buttonHeight,
            ),
          ),
          child: buttonContent,
        );
        break;
      case AppButtonType.secondary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                backgroundColor ??
                (isLight
                    ? AppColors.surfaceVariantLight
                    : AppColors.surfaceVariantDark),
            foregroundColor: isLight
                ? AppColors.textPrimaryLight
                : AppColors.textPrimaryDark,
            elevation: 0,
            minimumSize: Size(
              isFullWidth ? double.infinity : 0,
              AppDimensions.buttonHeight,
            ),
          ),
          child: buttonContent,
        );
        break;
      case AppButtonType.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            minimumSize: Size(
              isFullWidth ? double.infinity : 0,
              AppDimensions.buttonHeight,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
          ),
          child: buttonContent,
        );
        break;
      case AppButtonType.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            minimumSize: Size(
              isFullWidth ? double.infinity : 0,
              AppDimensions.buttonHeight,
            ),
          ),
          child: buttonContent,
        );
        break;
    }

    return button;
  }

  Color _getLoadingColor(bool isLight) {
    switch (type) {
      case AppButtonType.primary:
        return Colors.white;
      case AppButtonType.secondary:
        return isLight ? AppColors.textPrimaryLight : AppColors.textPrimaryDark;
      case AppButtonType.outline:
      case AppButtonType.text:
        return AppColors.primary;
    }
  }
}

enum AppButtonType { primary, secondary, outline, text }
