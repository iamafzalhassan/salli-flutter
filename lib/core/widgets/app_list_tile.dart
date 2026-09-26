import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';
import 'app_pressable.dart';

class AppListTile extends StatelessWidget {
  const AppListTile({super.key, required this.title, this.subtitle, this.onPressed, this.leading, this.trailing});

  final String title;

  final String? subtitle;

  final VoidCallback? onPressed;

  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final leading = this.leading;
    final subtitle = this.subtitle;
    final trailing = this.trailing ?? (onPressed == null ? null : Icon(Icons.chevron_right_rounded, color: colors.textSecondary, size: AppSpacing.iconSm));
    return AppPressable(
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            if (leading != null) ...[leading, const SizedBox(width: AppSpacing.md)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyStrong),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(color: colors.textSecondary, fontFeatures: AppTextStyles.tabular),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: AppSpacing.md), trailing],
          ],
        ),
      ),
    );
  }
}
