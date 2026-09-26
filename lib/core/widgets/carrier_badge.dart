import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../localization/locale_keys.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';
import '../utils/mobile_operator.dart';

class CarrierBadge extends StatelessWidget {
  const CarrierBadge({super.key, required this.carrier});

  final MobileOperator carrier;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.pill), color: colors.surfaceRaised),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Text(context.tr('${LocaleKeys.carrierPrefix}.${carrier.name}'), maxLines: 1, style: AppTextStyles.label.copyWith(color: colors.accentInk)),
    );
  }
}
