import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../localization/locale_keys.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';
import '../utils/lkr_format.dart';
import '../utils/money.dart';

class UsageBar extends StatelessWidget {
  const UsageBar({super.key, required this.label, required this.limit, required this.used});

  final String label;

  final Money limit;
  final Money used;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final symbol = context.tr(LocaleKeys.currencySymbol);
    final ratio = limit.isPositive ? (used.cents / limit.cents).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.label),
            ),
            Text(
              context.tr(LocaleKeys.accountUsedOf, args: [LkrFormat.withSymbol(used, symbol), LkrFormat.withSymbol(limit, symbol)]),
              maxLines: 1,
              style: AppTextStyles.caption.copyWith(color: colors.textSecondary, fontFeatures: AppTextStyles.tabular),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: SizedBox(
            height: AppSpacing.sm,
            child: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: colors.surfaceRaised)),
                TweenAnimationBuilder<double>(
                  builder: (context, value, _) => FractionallySizedBox(
                    widthFactor: value,
                    child: ColoredBox(color: ratio >= 1 ? colors.danger : colors.accentInk),
                  ),
                  curve: AppMotion.emphasized,
                  duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppMotion.hero,
                  tween: Tween(begin: 0, end: ratio),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
