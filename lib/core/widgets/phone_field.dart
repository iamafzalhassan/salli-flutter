import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../localization/locale_keys.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';
import '../utils/mobile_operator.dart';
import '../utils/phone_number.dart';
import 'carrier_badge.dart';

class PhoneField extends StatelessWidget {
  const PhoneField({super.key, this.autofocus = true, required this.isEnabled, required this.carrier, this.controller, required this.onChanged, required this.onSubmitted});

  final bool autofocus;
  final bool isEnabled;

  final MobileOperator? carrier;

  final TextEditingController? controller;

  final ValueChanged<String> onChanged;

  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final carrier = this.carrier;
    final textStyle = AppTextStyles.bodyStrong.copyWith(color: colors.textPrimary, fontFeatures: AppTextStyles.tabular);
    return AnimatedContainer(
      curve: AppMotion.standard,
      decoration: BoxDecoration(
        border: Border.all(color: carrier == null ? colors.border : colors.accentInk, width: AppSpacing.hairline),
        borderRadius: BorderRadius.circular(AppRadius.md),
        color: colors.surface,
      ),
      duration: AppMotion.base,
      height: AppSpacing.controlHeight,
      padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.sm),
      child: Row(
        children: [
          Text(PhoneNumber.countryCode, maxLines: 1, style: textStyle),
          const SizedBox(width: AppSpacing.md),
          Container(color: colors.border, height: AppSpacing.iconMd, width: AppSpacing.hairline),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: TextField(
              autofocus: autofocus,
              controller: controller,
              decoration: InputDecoration.collapsed(
                hintStyle: textStyle.copyWith(color: colors.textSecondary),
                hintText: context.tr(LocaleKeys.authPhoneHint),
              ),
              enabled: isEnabled,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(PhoneNumber.maxInputDigits)],
              keyboardType: TextInputType.phone,
              onChanged: onChanged,
              onSubmitted: (_) => onSubmitted(),
              style: textStyle,
              textInputAction: TextInputAction.done,
            ),
          ),
          AnimatedSwitcher(
            duration: AppMotion.base,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: carrier == null ? const SizedBox.shrink() : CarrierBadge(key: ValueKey(carrier), carrier: carrier),
          ),
        ],
      ),
    );
  }
}
