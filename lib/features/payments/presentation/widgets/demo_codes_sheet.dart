import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/lanka_qr.dart';
import '../../../../core/utils/lkr_format.dart';
import '../../../../core/utils/phone_number.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../../core/widgets/avatar.dart';

class DemoCodesSheet extends StatelessWidget {
  const DemoCodesSheet({super.key, required this.codes});

  static const double _maxHeightScale = 0.6;

  final List<String> codes;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(context.tr(LocaleKeys.scanDemoTitle), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.title),
      const SizedBox(height: AppSpacing.xs),
      Text(context.tr(LocaleKeys.scanDemoBody), style: AppTextStyles.body.copyWith(color: context.colors.textSecondary)),
      const SizedBox(height: AppSpacing.md),
      ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * _maxHeightScale),
        child: ListView(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          children: [for (final payload in codes) _DemoCodeTile(payload: payload)],
        ),
      ),
    ],
  );
}

class _DemoCodeTile extends StatelessWidget {
  const _DemoCodeTile({required this.payload});

  final String payload;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final code = LankaQr.parse(payload);
    final amount = code.amount;
    return AppPressable(
      onPressed: () => Navigator.of(context).pop(payload),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            if (code.isPersonal)
              Avatar(name: code.name)
            else
              Container(
                decoration: BoxDecoration(color: colors.surfaceRaised, shape: BoxShape.circle),
                height: AppSpacing.touchTarget,
                width: AppSpacing.touchTarget,
                child: Icon(Icons.storefront_rounded, color: colors.textPrimary, size: AppSpacing.iconSm),
              ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(code.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyStrong),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    code.isPersonal ? PhoneNumber.tryParse(code.accountId)?.display ?? code.accountId : code.city,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(color: colors.textSecondary, fontFeatures: AppTextStyles.tabular),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              amount == null ? context.tr(LocaleKeys.scanAnyAmount) : LkrFormat.withSymbol(amount, context.tr(LocaleKeys.currencySymbol)),
              maxLines: 1,
              style: AppTextStyles.amount.copyWith(color: amount == null ? colors.textSecondary : colors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
