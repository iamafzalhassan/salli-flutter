import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';
import 'app_button.dart';

class StatusMessage extends StatelessWidget {
  const StatusMessage({super.key, required this.body, required this.title, this.actionLabel, required this.icon, this.onAction});

  final String body;
  final String title;

  final String? actionLabel;

  final IconData icon;

  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final actionLabel = this.actionLabel;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(color: colors.surfaceRaised, shape: BoxShape.circle),
            height: AppSpacing.iconHero,
            width: AppSpacing.iconHero,
            child: Icon(icon, color: colors.accentInk, size: AppSpacing.iconLg),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: AppTextStyles.title, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            style: AppTextStyles.body.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null) ...[const SizedBox(height: AppSpacing.xl), AppButton(label: actionLabel, onPressed: onAction, variant: AppButtonVariant.secondary)],
        ],
      ),
    );
  }
}
