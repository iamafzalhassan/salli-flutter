import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../localization/locale_keys.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';
import '../widgets/app_button.dart';
import 'app_routes.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            children: [
              const Spacer(),
              Container(
                decoration: BoxDecoration(color: colors.surfaceRaised, shape: BoxShape.circle),
                height: AppSpacing.iconHero,
                width: AppSpacing.iconHero,
                child: Icon(Icons.construction_rounded, color: colors.accentInk, size: AppSpacing.iconLg),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(context.tr(LocaleKeys.notFoundTitle), style: AppTextStyles.headline, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.tr(LocaleKeys.notFoundBody),
                style: AppTextStyles.body.copyWith(color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              AppButton(label: context.tr(LocaleKeys.notFoundAction), onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home), variant: AppButtonVariant.secondary),
            ],
          ),
        ),
      ),
    );
  }
}
