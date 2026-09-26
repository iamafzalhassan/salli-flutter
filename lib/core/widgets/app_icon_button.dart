import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';
import 'app_pressable.dart';

class AppIconButton extends StatelessWidget {
  const AppIconButton({super.key, required this.semanticLabel, required this.icon, this.onPressed});

  final String semanticLabel;

  final IconData icon;

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: semanticLabel,
      child: AppPressable(
        onPressed: onPressed,
        child: Container(
          decoration: BoxDecoration(color: colors.surfaceRaised, shape: BoxShape.circle),
          height: AppSpacing.touchTarget,
          width: AppSpacing.touchTarget,
          child: Icon(icon, color: colors.textPrimary, size: AppSpacing.iconSm),
        ),
      ),
    );
  }
}
