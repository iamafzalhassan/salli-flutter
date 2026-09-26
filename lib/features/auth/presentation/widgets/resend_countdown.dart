import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_text_button.dart';

class ResendCountdown extends StatelessWidget {
  const ResendCountdown({super.key, required this.isBusy, required this.secondsLeft, this.onResend});

  final bool isBusy;

  final int secondsLeft;

  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: AppSpacing.touchTarget,
      child: Center(
        child: AnimatedSwitcher(
          duration: AppMotion.fast,
          child: switch ((isBusy, secondsLeft)) {
            (true, _) => const AppLoader(),
            (false, > 0) => Text(
              context.tr(LocaleKeys.authOtpResendIn, args: ['${secondsLeft ~/ Duration.secondsPerMinute}:${(secondsLeft % Duration.secondsPerMinute).toString().padLeft(2, '0')}']),
              key: const ValueKey('countdown'),
              maxLines: 1,
              style: AppTextStyles.label.copyWith(color: colors.textSecondary),
            ),
            _ => AppTextButton(key: const ValueKey('resend'), label: context.tr(LocaleKeys.authOtpResend), onPressed: onResend),
          },
        ),
      ),
    );
  }
}
