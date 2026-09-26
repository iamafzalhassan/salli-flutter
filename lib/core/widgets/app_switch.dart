import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';
import 'app_pressable.dart';

class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, this.onChanged});

  final bool value;

  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final onChanged = this.onChanged;
    return Semantics(
      toggled: value,
      child: AppPressable(
        onPressed: onChanged == null ? null : () => onChanged(!value),
        child: AnimatedOpacity(
          duration: AppMotion.fast,
          opacity: onChanged == null ? AppMotion.disabledOpacity : 1,
          child: AnimatedContainer(
            curve: AppMotion.standard,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.pill), color: value ? colors.accent : colors.surfaceRaised),
            duration: AppMotion.base,
            height: AppSpacing.switchHeight,
            padding: const EdgeInsets.all(AppSpacing.xs),
            width: AppSpacing.switchWidth,
            child: AnimatedAlign(
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              curve: AppMotion.emphasized,
              duration: AppMotion.base,
              child: AspectRatio(
                aspectRatio: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: value ? colors.onAccent : colors.textSecondary, shape: BoxShape.circle),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
