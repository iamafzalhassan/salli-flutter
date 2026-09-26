import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';
import 'app_pressable.dart';

class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({super.key, required this.options, required this.selected, required this.onChanged});

  final List<(T, String)> options;

  final T selected;

  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selectedIndex = options.indexWhere((option) => option.$1 == selected);
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.pill), color: colors.surfaceRaised),
      height: AppSpacing.touchTarget,
      padding: const EdgeInsets.all(AppSpacing.xxs),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: Alignment(options.length == 1 ? 0 : -1 + 2 * selectedIndex / (options.length - 1), 0),
            curve: AppMotion.emphasized,
            duration: AppMotion.base,
            child: FractionallySizedBox(
              heightFactor: 1,
              widthFactor: 1 / options.length,
              child: DecoratedBox(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.pill), color: colors.accent),
              ),
            ),
          ),
          Row(
            children: [
              for (final (value, label) in options)
                Expanded(
                  child: AppPressable(
                    onPressed: () => onChanged(value),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: AppMotion.base,
                        style: AppTextStyles.label.copyWith(color: value == selected ? colors.onAccent : colors.textSecondary),
                        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
