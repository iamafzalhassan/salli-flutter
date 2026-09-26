import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';
import 'app_pressable.dart';

class AppTextButton extends StatelessWidget {
  const AppTextButton({super.key, required this.label, this.onPressed});

  final String label;

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => AppPressable(
    onPressed: onPressed,
    child: AnimatedOpacity(
      duration: AppMotion.fast,
      opacity: onPressed == null ? AppMotion.disabledOpacity : 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.touchTarget, minWidth: AppSpacing.touchTarget),
        child: Center(
          heightFactor: 1,
          widthFactor: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label.copyWith(color: context.colors.accentInk, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    ),
  );
}
