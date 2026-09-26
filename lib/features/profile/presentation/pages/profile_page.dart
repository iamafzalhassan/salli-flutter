import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/failure_message.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/security/biometric_availability.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_segmented_control.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/entrance.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/pin_entry_sheet.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/settings_row.dart';
import '../../../../core/widgets/settings_toggle.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../settings/domain/entities/app_theme_mode.dart';
import '../cubits/profile_cubit.dart';
import '../cubits/profile_state.dart';
import '../widgets/language_sheet.dart';
import '../widgets/profile_card.dart';
import '../widgets/profile_card_skeleton.dart';
import '../widgets/sign_out_sheet.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static Widget _header(BuildContext context, ProfileState state) => switch ((state.status, state.profile)) {
    (_, final profile?) => ProfileCard(profile: profile),
    (ProfileStatus.failure, _) => StatusMessage(
      actionLabel: context.tr(LocaleKeys.commonRetry),
      body: context.failureMessage(state.failure!),
      icon: Icons.cloud_off_rounded,
      onAction: context.read<ProfileCubit>().load,
      title: context.tr(LocaleKeys.commonErrorTitle),
    ),
    _ => const ProfileCardSkeleton(),
  };

  static Future<void> _chooseLanguage(BuildContext context) => showAppSheet<void>(context, child: const LanguageSheet());

  static List<Widget> _security(BuildContext context, ProfileState state) {
    final biometrics = state.biometrics;
    final isEnrolled = biometrics?.availability == BiometricAvailability.available;
    return [
      const SizedBox(height: AppSpacing.xxl),
      SectionHeader(title: context.tr(LocaleKeys.profileSecurity)),
      const SizedBox(height: AppSpacing.md),
      Entrance(
        index: 3,
        child: SettingsRow(icon: Icons.shield_rounded, onPressed: () => unawaited(context.push<void>(AppRoutes.security)), title: context.tr(LocaleKeys.profileSecurityCenter)),
      ),
      if (biometrics != null && biometrics.availability != BiometricAvailability.unavailable) ...[
        const SizedBox(height: AppSpacing.md),
        Entrance(
          index: 3,
          child: SettingsToggle(
            icon: Icons.fingerprint_rounded,
            isBusy: state.isUpdatingBiometrics,
            onChanged: isEnrolled ? (isOn) => unawaited(_toggleBiometrics(context, isOn)) : null,
            subtitle: context.tr(isEnrolled ? LocaleKeys.profileBiometricsBody : LocaleKeys.profileBiometricsNotEnrolled),
            title: context.tr(LocaleKeys.profileBiometrics),
            value: biometrics.isEnabled,
          ),
        ),
        FailureText(failure: state.biometricFailure),
      ],
    ];
  }

  static Future<void> _toggleBiometrics(BuildContext context, bool isOn) async {
    final cubit = context.read<ProfileCubit>();
    if (!isOn) return cubit.disableBiometrics();
    final pin = await showAppSheet<String>(
      context,
      child: PinEntrySheet(body: context.tr(LocaleKeys.profileBiometricsPinBody), title: context.tr(LocaleKeys.profileBiometricsPinTitle)),
    );
    if (pin != null) await cubit.enableBiometrics(pin);
  }

  static Future<void> _confirmSignOut(BuildContext context) async {
    final cubit = context.read<ProfileCubit>();
    final confirmed = await showAppSheet<bool>(context, child: const SignOutSheet());
    if (confirmed ?? false) await cubit.signOut();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) => CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverSafeArea(
            bottom: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.only(bottom: AppSpacing.navClearance, left: AppSpacing.screenPadding, right: AppSpacing.screenPadding, top: AppSpacing.lg),
              sliver: SliverList.list(
                children: [
                  Text(context.tr(LocaleKeys.profileTitle), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.headline),
                  const SizedBox(height: AppSpacing.xl),
                  Entrance(child: _header(context, state)),
                  const SizedBox(height: AppSpacing.xxl),
                  SectionHeader(title: context.tr(LocaleKeys.profilePreferences)),
                  const SizedBox(height: AppSpacing.md),
                  Entrance(
                    index: 1,
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.tr(LocaleKeys.profileAppearance), maxLines: 1, style: AppTextStyles.bodyStrong),
                          const SizedBox(height: AppSpacing.md),
                          AppSegmentedControl<AppThemeMode>(
                            onChanged: (mode) => unawaited(context.read<ProfileCubit>().setThemeMode(mode)),
                            options: [(AppThemeMode.dark, context.tr(LocaleKeys.profileThemeDark)), (AppThemeMode.light, context.tr(LocaleKeys.profileThemeLight)), (AppThemeMode.system, context.tr(LocaleKeys.profileThemeSystem))],
                            selected: state.themeMode,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Entrance(
                    index: 2,
                    child: SettingsRow(
                      icon: Icons.translate_rounded,
                      onPressed: () => _chooseLanguage(context),
                      title: context.tr(LocaleKeys.profileLanguage),
                      value: context.tr('${LocaleKeys.languagePrefix}.${AppLanguage.fromLocale(context.locale).code}'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Entrance(
                    index: 2,
                    child: SettingsRow(icon: Icons.verified_user_rounded, onPressed: () => unawaited(context.push<void>(AppRoutes.account)), title: context.tr(LocaleKeys.profileAccount)),
                  ),
                  ..._security(context, state),
                  const SizedBox(height: AppSpacing.xxl),
                  Entrance(
                    index: 4,
                    child: AppButton(isLoading: state.isSigningOut, label: context.tr(LocaleKeys.profileSignOut), onPressed: () => _confirmSignOut(context), variant: AppButtonVariant.secondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
