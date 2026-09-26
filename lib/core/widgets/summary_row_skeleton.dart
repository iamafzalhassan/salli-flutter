import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'skeleton.dart';

class SummaryRowSkeleton extends StatelessWidget {
  const SummaryRowSkeleton({super.key, this.isEmphasized = false});

  static const double _labelWidth = 72;
  static const double _valueWidth = 96;

  final bool isEmphasized;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      children: [
        const Skeleton.text(textStyle: AppTextStyles.label, width: _labelWidth),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Skeleton.text(textStyle: isEmphasized ? AppTextStyles.title : AppTextStyles.amount, width: _valueWidth),
          ),
        ),
      ],
    ),
  );
}
