import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';
import 'app_pressable.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  final String title;

  final String? actionLabel;

  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final actionLabel = this.actionLabel;
    return Row(
      children: [
        Expanded(
          child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.title),
        ),
        if (actionLabel != null)
          AppPressable(
            onPressed: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Text(
                actionLabel,
                maxLines: 1,
                style: AppTextStyles.label.copyWith(color: context.colors.accentInk, fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }
}
