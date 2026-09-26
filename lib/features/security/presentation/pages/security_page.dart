import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/date_labels.dart';
import '../../../../core/localization/failure_message.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_refresh_view.dart';
import '../../../../core/widgets/icon_avatar.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/settings_row.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../../core/widgets/tile_skeleton.dart';
import '../../domain/entities/security_event_kind.dart';
import '../cubits/security_cubit.dart';
import '../cubits/security_state.dart';

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  static const int _skeletonEvents = 4;

  static const String _iosPlatform = 'ios';

  static const Map<SecurityEventKind, IconData> _icons = {
    SecurityEventKind.accountCreated: Icons.person_add_rounded,
    SecurityEventKind.biometricsDisabled: Icons.fingerprint_rounded,
    SecurityEventKind.biometricsEnabled: Icons.fingerprint_rounded,
    SecurityEventKind.cardFrozen: Icons.ac_unit_rounded,
    SecurityEventKind.cardLimitChanged: Icons.speed_rounded,
    SecurityEventKind.cardUnfrozen: Icons.credit_card_rounded,
    SecurityEventKind.newDevice: Icons.devices_rounded,
    SecurityEventKind.other: Icons.shield_rounded,
    SecurityEventKind.pinChanged: Icons.password_rounded,
    SecurityEventKind.pinReset: Icons.lock_reset_rounded,
    SecurityEventKind.signedIn: Icons.login_rounded,
  };

  static List<Widget> _content(BuildContext context, SecurityState state) {
    final colors = context.colors;
    return [
      for (final device in state.devices)
        AppListTile(
          leading: IconAvatar(icon: device.platform == _iosPlatform ? Icons.phone_iphone_rounded : Icons.phone_android_rounded),
          subtitle: context.tr(LocaleKeys.securityTrustedSince, args: [context.dateLabel(device.boundAt.toLocal())]),
          title: device.isCurrent ? context.tr(LocaleKeys.securityThisDevice, args: [_platformLabel(context, device.platform)]) : _platformLabel(context, device.platform),
          trailing: device.hasBiometricKey ? Icon(Icons.fingerprint_rounded, color: colors.accentInk, size: AppSpacing.iconMd) : null,
        ),
      const SizedBox(height: AppSpacing.xs),
      Text(context.tr(LocaleKeys.securityDeviceNote), style: AppTextStyles.caption.copyWith(color: colors.textSecondary)),
      const SizedBox(height: AppSpacing.xl),
      SectionHeader(title: context.tr(LocaleKeys.securityActivity)),
      const SizedBox(height: AppSpacing.sm),
      for (final event in state.events)
        AppListTile(
          leading: IconAvatar(icon: _icons[event.kind] ?? Icons.shield_rounded, isAccent: false),
          subtitle: [context.momentLabel(event.createdAt), _platformLabel(context, event.platform)].where((part) => part.isNotEmpty).join(context.tr(LocaleKeys.securitySeparator)),
          title: context.tr('${LocaleKeys.securityEventPrefix}.${event.kind.name}'),
        ),
    ];
  }

  static String _platformLabel(BuildContext context, String? platform) => switch (platform) {
    null => '',
    _iosPlatform => context.tr(LocaleKeys.securityIphone),
    _ => context.tr(LocaleKeys.securityAndroid),
  };

  @override
  Widget build(BuildContext context) => BlocBuilder<SecurityCubit, SecurityState>(
    builder: (context, state) => Scaffold(
      body: SafeArea(
        child: AppRefreshView(
          onRefresh: context.read<SecurityCubit>().load,
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            PageHeader(title: context.tr(LocaleKeys.securityTitle)),
            const SizedBox(height: AppSpacing.xl),
            SettingsRow(icon: Icons.password_rounded, onPressed: () => unawaited(context.push<void>(AppRoutes.changePin)), title: context.tr(LocaleKeys.securityChangePin)),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: context.tr(LocaleKeys.securityDevices)),
            const SizedBox(height: AppSpacing.sm),
            ...switch (state.status) {
              SecurityStatus.loading => [
                const TileSkeleton(),
                const SizedBox(height: AppSpacing.xs),
                Text(context.tr(LocaleKeys.securityDeviceNote), style: AppTextStyles.caption.copyWith(color: context.colors.textSecondary)),
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(title: context.tr(LocaleKeys.securityActivity)),
                const SizedBox(height: AppSpacing.sm),
                for (var index = 0; index < _skeletonEvents; index++) const TileSkeleton(),
              ],

              SecurityStatus.failure => [
                StatusMessage(
                  actionLabel: context.tr(LocaleKeys.commonRetry),
                  body: context.failureMessage(state.failure!),
                  icon: Icons.cloud_off_rounded,
                  onAction: context.read<SecurityCubit>().load,
                  title: context.tr(LocaleKeys.commonErrorTitle),
                ),
              ],
              SecurityStatus.ready => _content(context, state),
            },
          ],
        ),
      ),
    ),
  );
}
