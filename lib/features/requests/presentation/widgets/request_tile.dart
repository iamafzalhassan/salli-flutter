import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/date_labels.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/lkr_format.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/avatar.dart';
import '../../domain/entities/money_request.dart';
import '../../domain/entities/request_status.dart';

class RequestTile extends StatelessWidget {
  const RequestTile({super.key, this.actions = const [], required this.request});

  static const String _separator = ' · ';

  final List<Widget> actions;

  final MoneyRequest request;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final note = request.note;
    final statusColor = switch (request.status) {
      RequestStatus.paid => colors.success,
      RequestStatus.pending => colors.warning,
      RequestStatus.cancelled || RequestStatus.declined => colors.textSecondary,
    };
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Avatar(name: request.counterparty.name),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.counterparty.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyStrong),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      [?note, context.momentLabel(request.createdAt)].join(_separator),
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
                  Text(LkrFormat.withSymbol(request.amount, context.tr(LocaleKeys.currencySymbol)), maxLines: 1, style: AppTextStyles.amount),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(context.tr('${LocaleKeys.requestStatusPrefix}.${request.status.name}'), maxLines: 1, style: AppTextStyles.caption.copyWith(color: statusColor)),
                ],
              ),
            ],
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                for (final (index, action) in actions.indexed) ...[if (index > 0) const SizedBox(width: AppSpacing.sm), Expanded(child: action)],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
