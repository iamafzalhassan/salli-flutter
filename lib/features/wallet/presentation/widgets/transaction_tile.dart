import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/date_labels.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/lkr_format.dart';
import '../../../../core/utils/path_template.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../domain/entities/transaction_status.dart';
import '../../domain/entities/wallet_transaction.dart';
import 'transaction_icons.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, this.showsDay = false, required this.transaction});

  static const String _separator = ' · ';

  final bool showsDay;

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final moment = showsDay ? context.momentLabel(transaction.createdAt) : context.timeLabel(transaction.createdAt);
    final statusColor = transaction.status == TransactionStatus.failed ? colors.danger : colors.warning;
    return AppPressable(
      onPressed: () => unawaited(context.push<void>(AppRoutes.transaction.withId(transaction.id))),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(color: colors.surfaceRaised, shape: BoxShape.circle),
              height: AppSpacing.touchTarget,
              width: AppSpacing.touchTarget,
              child: Icon(TransactionIcons.of(transaction.type), color: colors.textPrimary, size: AppSpacing.iconSm),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transaction.counterpartyName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyStrong),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${context.tr('${LocaleKeys.transactionPrefix}.${transaction.type.name}')}$_separator$moment',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(LkrFormat.signed(transaction.amount, context.tr(LocaleKeys.currencySymbol)), maxLines: 1, style: AppTextStyles.amount.copyWith(color: transaction.isCredit ? colors.success : colors.textPrimary)),
                if (transaction.status != TransactionStatus.completed) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(context.tr('${LocaleKeys.transactionPrefix}.${transaction.status.name}'), maxLines: 1, style: AppTextStyles.caption.copyWith(color: statusColor)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
