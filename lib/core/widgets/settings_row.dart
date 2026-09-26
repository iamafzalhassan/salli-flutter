import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';
import 'app_card.dart';
import 'app_pressable.dart';

class SettingsRow extends StatelessWidget {
  const SettingsRow({super.key, required this.title, this.value, required this.icon, this.onPressed});

  final String title;

  final String? value;

  final IconData icon;

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final value = this.value;
    return AppPressable(
      onPressed: onPressed,
      child: AppCard(
        height: AppSpacing.controlHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding),
        child: Row(
          children: [
            Icon(icon, color: colors.textSecondary, size: AppSpacing.iconSm),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyStrong),
            ),
            if (value != null) Text(value, maxLines: 1, style: AppTextStyles.label.copyWith(color: colors.textSecondary)),
            if (onPressed != null) ...[const SizedBox(width: AppSpacing.xs), Icon(Icons.chevron_right_rounded, color: colors.textSecondary, size: AppSpacing.iconSm)],
          ],
        ),
      ),
    );
  }
}
