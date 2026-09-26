import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/date_labels.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_icon_button.dart';
import '../../../../core/widgets/avatar.dart';
import '../../../profile/domain/entities/profile.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, this.unreadCount = 0, required this.profile});

  static const double _badgeOffset = -2;
  static const double _badgeSize = AppSpacing.lg + AppSpacing.xs;

  static const int _maxBadgeCount = 9;

  final int unreadCount;

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Avatar(name: profile.displayName),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.greeting(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(profile.displayName ?? profile.phone.display, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.title),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            AppIconButton(
              icon: unreadCount > 0 ? Icons.notifications_rounded : Icons.notifications_none_rounded,
              onPressed: () => unawaited(context.push<void>(AppRoutes.notifications)),
              semanticLabel: unreadCount > 0 ? context.tr(LocaleKeys.homeNotificationsUnread, args: ['$unreadCount']) : context.tr(LocaleKeys.homeNotifications),
            ),
            if (unreadCount > 0)
              PositionedDirectional(
                end: _badgeOffset,
                top: _badgeOffset,
                child: ExcludeSemantics(
                  child: Container(
                    alignment: Alignment.center,
                    constraints: const BoxConstraints(minHeight: _badgeSize, minWidth: _badgeSize),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.pill), color: colors.accent),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    child: Text(
                      unreadCount > _maxBadgeCount ? context.tr(LocaleKeys.homeUnreadMany) : '$unreadCount',
                      maxLines: 1,
                      style: AppTextStyles.caption.copyWith(color: colors.onAccent, fontFeatures: AppTextStyles.tabular, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
