import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../domain/entities/step_up_reason.dart';

class StepUpNotice extends StatelessWidget {
  const StepUpNotice({super.key, required this.reasons});

  static const Map<StepUpReason, String> _reasonKeys = {StepUpReason.largeAmount: LocaleKeys.reviewStepUpLargeAmount, StepUpReason.newDevice: LocaleKeys.reviewStepUpNewDevice, StepUpReason.newPayee: LocaleKeys.reviewStepUpNewPayee};

  final Set<StepUpReason> reasons;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.warning, width: AppSpacing.hairline),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: colors.surface,
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_moon_rounded, color: colors.warning, size: AppSpacing.iconMd),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr(LocaleKeys.reviewStepUpTitle), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyStrong),
                const SizedBox(height: AppSpacing.xs),
                for (final reason in StepUpReason.values.where(reasons.contains))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(context.tr(_reasonKeys[reason]!), style: AppTextStyles.caption.copyWith(color: colors.textSecondary)),
                  ),
                Text(context.tr(LocaleKeys.reviewStepUpBody), style: AppTextStyles.caption.copyWith(color: colors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
