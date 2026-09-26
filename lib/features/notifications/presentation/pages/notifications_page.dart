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
import '../../../../core/utils/path_template.dart';
import '../../../../core/widgets/app_icon_button.dart';
import '../../../../core/widgets/app_refresh_view.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../../core/widgets/tile_skeleton.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_kind.dart';
import '../cubits/notifications_cubit.dart';
import '../cubits/notifications_state.dart';
import '../widgets/notification_tile.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static const double _daySkeletonWidth = 72;
  static const double _momentSkeletonWidth = 40;

  static const int _skeletonRows = 6;

  static List<Widget> _rows(BuildContext context, NotificationsState state) {
    final colors = context.colors;
    return switch (state.status) {
      NotificationsStatus.loading => [
        const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.xs),
          child: Skeleton.text(textStyle: AppTextStyles.overline, width: _daySkeletonWidth),
        ),
        for (var index = 0; index < _skeletonRows; index++)
          const TileSkeleton(
            crossAxisAlignment: CrossAxisAlignment.start,
            subtitleLines: 2,
            trailing: Skeleton.text(textStyle: AppTextStyles.caption, width: _momentSkeletonWidth),
          ),
      ],
      NotificationsStatus.failure => [
        StatusMessage(
          actionLabel: context.tr(LocaleKeys.commonRetry),
          body: context.failureMessage(state.failure!),
          icon: Icons.cloud_off_rounded,
          onAction: context.read<NotificationsCubit>().load,
          title: context.tr(LocaleKeys.commonErrorTitle),
        ),
      ],
      NotificationsStatus.ready when state.items.isEmpty => [StatusMessage(body: context.tr(LocaleKeys.notificationsEmptyBody), icon: Icons.notifications_none_rounded, title: context.tr(LocaleKeys.notificationsEmptyTitle))],
      NotificationsStatus.ready => [
        for (final (index, notification) in state.items.indexed) ...[
          if (index == 0 || !DateUtils.isSameDay(state.items[index - 1].createdAt.toLocal(), notification.createdAt.toLocal()))
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.xs, top: index == 0 ? 0 : AppSpacing.xl),
              child: Text(context.dayLabel(notification.createdAt).toUpperCase(), maxLines: 1, style: AppTextStyles.overline.copyWith(color: colors.textSecondary)),
            ),
          NotificationTile(key: ValueKey(notification.id), notification: notification, onPressed: () => _open(context, notification)),
        ],
      ],
    };
  }

  static void _open(BuildContext context, AppNotification notification) {
    unawaited(context.read<NotificationsCubit>().open(notification));
    final transactionId = notification.transactionId;
    switch (notification.kind) {
      case NotificationKind.moneyReceived || NotificationKind.requestPaid when transactionId != null:
        unawaited(context.push<void>(AppRoutes.transaction.withId(transactionId)));
      case NotificationKind.requestReceived:
        unawaited(context.push<void>(AppRoutes.requests));
      case NotificationKind.cashbackEarned || NotificationKind.referralJoined || NotificationKind.scratchCardEarned:
        context.go(AppRoutes.rewards);
      case NotificationKind.kycRejected || NotificationKind.kycVerified:
        unawaited(context.push<void>(AppRoutes.account));
      case _:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<NotificationsCubit, NotificationsState>(
    builder: (context, state) {
      final cubit = context.read<NotificationsCubit>();
      final rows = _rows(context, state);
      return Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.screenPadding, AppSpacing.screenPadding, AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(child: PageHeader(title: context.tr(LocaleKeys.notificationsTitle))),
                    if (state.hasUnread) AppIconButton(icon: Icons.done_all_rounded, onPressed: () => unawaited(cubit.markAllRead()), semanticLabel: context.tr(LocaleKeys.notificationsMarkAllRead)),
                  ],
                ),
              ),
              Expanded(
                child: AppRefreshView(onRefresh: cubit.load, padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 0, AppSpacing.screenPadding, AppSpacing.screenPadding), children: rows),
              ),
            ],
          ),
        ),
      );
    },
  );
}
