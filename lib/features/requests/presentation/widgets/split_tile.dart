import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/date_labels.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/lkr_format.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/bill_split.dart';
import '../../domain/entities/request_status.dart';

class SplitTile extends StatelessWidget {
  const SplitTile({super.key, required this.split});

  static const String _separator = ' · ';

  final BillSplit split;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final symbol = context.tr(LocaleKeys.currencySymbol);
    final note = split.note;
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(note ?? context.tr(LocaleKeys.splitUntitled), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyStrong),
              ),
              Text(LkrFormat.withSymbol(split.total, symbol), maxLines: 1, style: AppTextStyles.amount),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            [
              context.tr(LocaleKeys.splitPaidCount, namedArgs: {'paid': '${split.paidCount}', 'total': '${split.requestCount}'}),
              context.dayLabel(split.createdAt),
            ].join(_separator),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final share in split.shares)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
              child: Row(
                children: [
                  Icon(share.status == RequestStatus.paid ? Icons.check_circle_rounded : Icons.schedule_rounded, color: share.status == RequestStatus.paid ? colors.success : colors.warning, size: AppSpacing.iconXs),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(share.isSelf ? context.tr(LocaleKeys.splitYou) : share.payee?.displayName ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.label),
                  ),
                  Text(LkrFormat.withSymbol(share.amount, symbol), maxLines: 1, style: AppTextStyles.label.copyWith(fontFeatures: AppTextStyles.tabular)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
