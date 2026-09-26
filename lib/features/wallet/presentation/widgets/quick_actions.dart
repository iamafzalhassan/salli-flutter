import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/action_tile.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  static const List<(IconData, String, String)> _actions = [
    (Icons.arrow_upward_rounded, LocaleKeys.homeActionSend, AppRoutes.send),
    (Icons.arrow_downward_rounded, LocaleKeys.homeActionRequest, AppRoutes.request),
    (Icons.receipt_long_rounded, LocaleKeys.homeActionBills, AppRoutes.bills),
    (Icons.phone_android_rounded, LocaleKeys.homeActionReload, AppRoutes.reload),
  ];

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final (index, (icon, labelKey, route)) in _actions.indexed) ...[
        if (index > 0) const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ActionTile(icon: icon, isPrimary: index == 0, label: context.tr(labelKey), onPressed: () => unawaited(context.push<void>(route))),
        ),
      ],
    ],
  );
}
