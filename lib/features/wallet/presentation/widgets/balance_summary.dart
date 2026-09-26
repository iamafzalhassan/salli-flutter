import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/animated_money.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../domain/entities/wallet.dart';

class BalanceSummary extends StatelessWidget {
  const BalanceSummary({super.key, required this.isHidden, required this.onToggle, required this.wallet});

  final bool isHidden;

  final VoidCallback onToggle;

  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(context.tr(LocaleKeys.homeBalance), maxLines: 1, style: AppTextStyles.label.copyWith(color: colors.textSecondary)),
            const SizedBox(width: AppSpacing.xs),
            Semantics(
              label: context.tr(isHidden ? LocaleKeys.homeShowBalance : LocaleKeys.homeHideBalance),
              child: AppPressable(
                onPressed: onToggle,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: AnimatedSwitcher(
                    duration: AppMotion.fast,
                    child: Icon(isHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded, key: ValueKey(isHidden), color: colors.textSecondary, size: AppSpacing.iconSm),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        AnimatedMoney(
          isHidden: isHidden,
          money: wallet.balance,
          style: AppTextStyles.balance.copyWith(color: colors.textPrimary),
          symbol: context.tr(LocaleKeys.currencySymbol),
        ),
      ],
    );
  }
}
