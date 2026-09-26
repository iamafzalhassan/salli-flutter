import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/date_labels.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../domain/entities/timeline_status.dart';
import '../../domain/entities/timeline_step.dart';

class TimelineRow extends StatelessWidget {
  const TimelineRow({super.key, this.isLast = false, required this.step});

  static const Map<TimelineStatus, String> labels = {
    TimelineStatus.completed: LocaleKeys.transactionDetailStepCompleted,
    TimelineStatus.failed: LocaleKeys.transactionDetailStepFailed,
    TimelineStatus.initiated: LocaleKeys.transactionDetailStepInitiated,
    TimelineStatus.pending: LocaleKeys.transactionDetailStepPending,
  };

  final bool isLast;

  final TimelineStep step;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = switch (step.status) {
      TimelineStatus.completed => colors.success,
      TimelineStatus.failed => colors.danger,
      TimelineStatus.initiated => colors.textSecondary,
      TimelineStatus.pending => colors.warning,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const SizedBox(height: AppSpacing.xs),
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.pill), color: color),
              height: AppSpacing.md,
              width: AppSpacing.md,
            ),
            if (!isLast) Container(color: colors.border, height: AppSpacing.xxl, width: AppSpacing.xxs),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr(labels[step.status]!), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyStrong),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                context.momentLabel(step.at),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
