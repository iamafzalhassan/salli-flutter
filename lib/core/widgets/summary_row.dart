import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';

class SummaryRow extends StatelessWidget {
  const SummaryRow({super.key, this.isEmphasized = false, required this.label, required this.value});

  final bool isEmphasized;

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Text(label, maxLines: 1, style: AppTextStyles.label.copyWith(color: colors.textSecondary)),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (isEmphasized ? AppTextStyles.title : AppTextStyles.amount).copyWith(color: colors.textPrimary, fontFeatures: AppTextStyles.tabular),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
