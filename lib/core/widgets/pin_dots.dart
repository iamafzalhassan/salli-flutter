import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';

class PinDots extends StatelessWidget {
  const PinDots({super.key, required this.hasError, required this.filled, required this.length});

  final bool hasError;

  final int filled;
  final int length;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final activeColor = hasError ? colors.danger : colors.accent;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < length; index++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: AnimatedContainer(
              curve: AppMotion.emphasized,
              decoration: BoxDecoration(
                border: Border.all(color: index < filled || hasError ? activeColor : colors.border, width: AppSpacing.progressStroke),
                color: index < filled ? activeColor : Colors.transparent,
                shape: BoxShape.circle,
              ),
              duration: AppMotion.base,
              height: AppSpacing.pinDot,
              width: AppSpacing.pinDot,
            ),
          ),
      ],
    );
  }
}
