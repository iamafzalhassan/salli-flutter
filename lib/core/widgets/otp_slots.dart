import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';

class OtpSlots extends StatelessWidget {
  const OtpSlots({super.key, required this.hasError, required this.length, required this.value});

  final bool hasError;

  final int length;

  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        for (var index = 0; index < length; index++) ...[
          if (index > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AnimatedContainer(
              alignment: Alignment.center,
              curve: AppMotion.standard,
              decoration: BoxDecoration(
                border: Border.all(color: hasError ? colors.danger : (index == value.length ? colors.accentInk : colors.border), width: AppSpacing.hairline),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                color: colors.surface,
              ),
              duration: AppMotion.fast,
              height: AppSpacing.controlHeight,
              child: AnimatedSwitcher(
                duration: AppMotion.fast,
                transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                child: Text(
                  index < value.length ? value[index] : '',
                  key: ValueKey(index < value.length),
                  maxLines: 1,
                  style: AppTextStyles.headline.copyWith(color: colors.textPrimary),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
