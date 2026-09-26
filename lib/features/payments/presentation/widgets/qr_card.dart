import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/lkr_format.dart';
import '../../../../core/utils/money.dart';

class QrCard extends StatelessWidget {
  const QrCard({super.key, required this.name, required this.payload, required this.phone, this.amount});

  static const double codeSize = 216;

  final String name;
  final String payload;
  final String phone;

  final Money? amount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final amount = this.amount;
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.xl), color: colors.accent),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.title.copyWith(color: colors.onAccent),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            phone,
            maxLines: 1,
            style: AppTextStyles.label.copyWith(color: colors.onAccent, fontFeatures: AppTextStyles.tabular),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox.square(
            dimension: codeSize,
            child: QrImageView(
              data: payload,
              dataModuleStyle: QrDataModuleStyle(color: colors.onAccent, dataModuleShape: QrDataModuleShape.square),
              errorCorrectionLevel: QrErrorCorrectLevel.M,
              eyeStyle: QrEyeStyle(color: colors.onAccent, eyeShape: QrEyeShape.square),
              padding: EdgeInsets.zero,
              semanticsLabel: context.tr(LocaleKeys.myQrTitle),
              size: codeSize,
            ),
          ),
          if (amount != null) ...[
            const SizedBox(height: AppSpacing.lg),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                LkrFormat.withSymbol(amount, context.tr(LocaleKeys.currencySymbol)),
                maxLines: 1,
                style: AppTextStyles.headline.copyWith(color: colors.onAccent, fontFeatures: AppTextStyles.tabular),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.tr(LocaleKeys.myQrCardFooter),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.overline.copyWith(color: colors.onAccent),
          ),
        ],
      ),
    );
  }
}
