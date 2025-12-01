import 'package:flutter/material.dart';
import '../../core/constants/dimensions.dart';
import '../../core/theme/colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackTap;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return AppBar(
      title: Text(title),
      centerTitle: true,
      leading: showBackButton
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: isLight
                    ? AppColors.textPrimaryLight
                    : AppColors.textPrimaryDark,
              ),
              onPressed: onBackTap ?? () => Navigator.of(context).pop(),
            )
          : null,
      actions: actions != null
          ? [...actions!, const SizedBox(width: AppDimensions.space8)]
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
