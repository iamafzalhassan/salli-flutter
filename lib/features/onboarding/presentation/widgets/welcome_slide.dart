import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import 'welcome_illustration.dart';

class WelcomeSlide extends StatelessWidget {
  const WelcomeSlide({super.key, required this.bodyKey, required this.titleKey, required this.icon});

  final String bodyKey;
  final String titleKey;

  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
    child: Column(
      children: [
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: WelcomeIllustration(icon: icon),
            ),
          ),
        ),
        Text(context.tr(titleKey), style: AppTextStyles.headline, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.md),
        Text(
          context.tr(bodyKey),
          style: AppTextStyles.body.copyWith(color: context.colors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    ),
  );
}
