import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';
import 'app_pressable.dart';

class ActionTile extends StatelessWidget {
  const ActionTile({super.key, this.isPrimary = false, required this.label, required this.icon, required this.onPressed});

  final bool isPrimary;

  final String label;

  final IconData icon;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = isPrimary ? colors.onAccent : colors.textPrimary;
    return AppPressable(
      onPressed: onPressed,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.lg), color: isPrimary ? colors.accent : colors.surface),
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: foreground, size: AppSpacing.iconMd),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
