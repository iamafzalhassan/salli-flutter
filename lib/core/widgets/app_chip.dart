import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';
import 'app_pressable.dart';

class AppChip extends StatelessWidget {
  const AppChip({super.key, this.isSelected = false, required this.label, this.icon, this.onPressed});

  final bool isSelected;

  final String label;

  final IconData? icon;

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final icon = this.icon;
    final foreground = isSelected ? colors.onAccent : colors.textPrimary;
    return AppPressable(
      onPressed: onPressed,
      child: AnimatedContainer(
        curve: AppMotion.standard,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.pill), color: isSelected ? colors.accent : colors.surfaceRaised),
        duration: AppMotion.fast,
        height: AppSpacing.touchTarget,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, color: foreground, size: AppSpacing.iconXs), const SizedBox(width: AppSpacing.xs)],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label.copyWith(color: foreground, fontFeatures: AppTextStyles.tabular),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
