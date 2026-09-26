import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';
import 'app_loader.dart';
import 'app_pressable.dart';

enum AppButtonVariant { danger, primary, secondary }

class AppButton extends StatelessWidget {
  const AppButton({super.key, this.isLoading = false, required this.label, this.variant = AppButtonVariant.primary, this.onPressed});

  final bool isLoading;

  final String label;

  final AppButtonVariant variant;

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, foreground) = switch (variant) {
      AppButtonVariant.danger => (colors.danger, colors.background),
      AppButtonVariant.primary => (colors.accent, colors.onAccent),
      AppButtonVariant.secondary => (colors.surfaceRaised, colors.textPrimary),
    };
    return AppPressable(
      onPressed: isLoading ? null : onPressed,
      child: AnimatedOpacity(
        duration: AppMotion.fast,
        opacity: onPressed == null && !isLoading ? AppMotion.disabledOpacity : 1,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.md), color: background),
          height: AppSpacing.controlHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          width: double.infinity,
          child: AnimatedSwitcher(
            duration: AppMotion.fast,
            child: isLoading
                ? AppLoader(color: foreground)
                : Text(
                    label,
                    key: ValueKey(label),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyStrong.copyWith(color: foreground),
                  ),
          ),
        ),
      ),
    );
  }
}
