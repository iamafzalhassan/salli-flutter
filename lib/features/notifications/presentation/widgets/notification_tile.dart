import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/date_labels.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/lkr_format.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../../core/widgets/icon_avatar.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_kind.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.notification, this.onPressed});

  static const int _bodyLines = 2;

  static const String _bodySuffix = 'Body';
  static const String _titleSuffix = 'Title';

  static const Map<NotificationKind, IconData> _icons = {
    NotificationKind.cashbackEarned: Icons.savings_rounded,
    NotificationKind.kycRejected: Icons.badge_rounded,
    NotificationKind.kycVerified: Icons.verified_user_rounded,
    NotificationKind.moneyReceived: Icons.south_west_rounded,
    NotificationKind.other: Icons.notifications_rounded,
    NotificationKind.referralJoined: Icons.group_add_rounded,
    NotificationKind.requestPaid: Icons.task_alt_rounded,
    NotificationKind.requestReceived: Icons.inbox_rounded,
    NotificationKind.scratchCardEarned: Icons.auto_awesome_rounded,
    NotificationKind.welcome: Icons.waving_hand_rounded,
  };

  final AppNotification notification;

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final amount = notification.amount;
    final key = '${LocaleKeys.notificationPrefix}.${notification.kind.name}';
    final namedArgs = {'amount': amount == null ? '' : LkrFormat.withSymbol(amount, context.tr(LocaleKeys.currencySymbol)), 'name': notification.name ?? ''};
    return AppPressable(
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconAvatar(icon: _icons[notification.kind] ?? Icons.notifications_rounded, isAccent: !notification.isRead),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('$key$_titleSuffix', namedArgs: namedArgs),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyStrong,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    context.tr('$key$_bodySuffix', namedArgs: namedArgs),
                    maxLines: _bodyLines,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(context.momentLabel(notification.createdAt), maxLines: 1, style: AppTextStyles.caption.copyWith(color: colors.textSecondary)),
                if (!notification.isRead) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.pill), color: colors.accentInk),
                    height: AppSpacing.sm,
                    width: AppSpacing.sm,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
