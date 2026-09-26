import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/date_labels.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/lkr_format.dart';
import '../../../../core/widgets/avatar.dart';
import '../../../../core/widgets/category_icons.dart';
import '../../../../core/widgets/icon_avatar.dart';
import '../../domain/entities/funding_source_type.dart';
import '../../domain/entities/recipient.dart';

class RecipientHeader extends StatelessWidget {
  const RecipientHeader({super.key, required this.recipient});

  static const String _separator = ' · ';

  final Recipient recipient;

  static String? _detail(BuildContext context, Recipient recipient) {
    if (recipient is! BillRecipient) return null;
    final amountDue = recipient.amountDue;
    final dueDate = recipient.dueDate;
    final parts = [
      ?recipient.customerName,
      if (amountDue != null && dueDate != null) context.tr(LocaleKeys.billsDueBy, args: [LkrFormat.withSymbol(amountDue, context.tr(LocaleKeys.currencySymbol)), context.dayLabel(dueDate)]),
    ];
    return parts.isEmpty ? null : parts.join(_separator);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final recipient = this.recipient;
    final detail = _detail(context, recipient);
    return Column(
      children: [
        switch (recipient) {
          PersonRecipient(:final payee) => Avatar(name: payee.name, size: AppSpacing.iconHero),
          MerchantRecipient(:final merchant) => IconAvatar(icon: CategoryIcons.of(merchant.category.name), size: AppSpacing.iconHero),
          BillRecipient(:final category) => IconAvatar(icon: CategoryIcons.of(category.name), size: AppSpacing.iconHero),
          ReloadRecipient() => const IconAvatar(icon: Icons.phone_android_rounded, size: AppSpacing.iconHero),
          BankRecipient() => IconAvatar(icon: CategoryIcons.of('bank'), size: AppSpacing.iconHero),
          TopUpRecipient(:final type) => IconAvatar(icon: type == FundingSourceType.card ? Icons.credit_card_rounded : Icons.account_balance_rounded, size: AppSpacing.iconHero),
          WithdrawalRecipient() => const IconAvatar(icon: Icons.account_balance_rounded, size: AppSpacing.iconHero),
        },
        const SizedBox(height: AppSpacing.md),
        Text(
          recipient.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.title.copyWith(fontFeatures: AppTextStyles.tabular),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          switch (recipient) {
            PersonRecipient(:final payee) => payee.phone.display,
            MerchantRecipient(:final merchant) => merchant.city,
            BillRecipient(:final accountNumber) => accountNumber,
            ReloadRecipient(:final phone, :final planName) => [context.tr('${LocaleKeys.carrierPrefix}.${phone.carrier.name}'), ?planName].join(_separator),
            BankRecipient(:final bankShortName, :final accountNumber) => [bankShortName, accountNumber].join(_separator),
            TopUpRecipient(:final type) => context.tr('${LocaleKeys.fundingTypePrefix}.${type.name}'),
            WithdrawalRecipient() => context.tr('${LocaleKeys.fundingTypePrefix}.${FundingSourceType.bank.name}'),
          },
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.label.copyWith(color: colors.textSecondary, fontFeatures: AppTextStyles.tabular),
        ),
        if (detail != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(color: colors.textSecondary, fontFeatures: AppTextStyles.tabular),
          ),
        ],
        if (recipient is MerchantRecipient) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_rounded, color: colors.accentInk, size: AppSpacing.iconXs),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  context.tr(LocaleKeys.merchantVerified),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(color: colors.accentInk, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
