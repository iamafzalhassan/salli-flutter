import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';

class SelectionMark extends StatelessWidget {
  const SelectionMark({super.key, required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedContainer(
      curve: AppMotion.standard,
      decoration: BoxDecoration(
        border: Border.all(color: isSelected ? colors.accent : colors.border, width: AppSpacing.progressStroke),
        color: isSelected ? colors.accent : Colors.transparent,
        shape: BoxShape.circle,
      ),
      duration: AppMotion.base,
      height: AppSpacing.iconMd,
      width: AppSpacing.iconMd,
      child: AnimatedScale(
        curve: AppMotion.emphasized,
        duration: AppMotion.base,
        scale: isSelected ? 1 : 0,
        child: Icon(Icons.check_rounded, color: colors.onAccent, size: AppSpacing.lg),
      ),
    );
  }
}
