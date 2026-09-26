import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/security/runtime_threat.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/icon_avatar.dart';

class SecurityAlertPage extends StatelessWidget {
  const SecurityAlertPage({super.key, required this.threats});

  final Set<RuntimeThreat> threats;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              Icon(Icons.gpp_bad_rounded, color: colors.danger, size: AppSpacing.iconHero),
              const SizedBox(height: AppSpacing.xl),
              Text(context.tr(LocaleKeys.securityAlertTitle), style: AppTextStyles.headline, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.tr(LocaleKeys.securityAlertBody),
                style: AppTextStyles.body.copyWith(color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: ListView(
                  children: [
                    for (final threat in threats)
                      AppListTile(
                        leading: const IconAvatar(icon: Icons.warning_amber_rounded, isAccent: false),
                        subtitle: context.tr('${LocaleKeys.runtimeThreatPrefix}.${threat.name}Body'),
                        title: context.tr('${LocaleKeys.runtimeThreatPrefix}.${threat.name}Title'),
                      ),
                  ],
                ),
              ),
              AppButton(label: context.tr(LocaleKeys.securityAlertHome), onPressed: () => context.go(AppRoutes.home)),
            ],
          ),
        ),
      ),
    );
  }
}
