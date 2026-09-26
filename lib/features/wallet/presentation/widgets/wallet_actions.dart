import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_chip.dart';

class WalletActions extends StatelessWidget {
  const WalletActions({super.key});

  static const List<(IconData, String, String)> _actions = [
    (Icons.add_rounded, LocaleKeys.homeAddMoney, AppRoutes.addMoney),
    (Icons.south_rounded, LocaleKeys.homeWithdraw, AppRoutes.withdraw),
    (Icons.credit_card_rounded, LocaleKeys.homeCard, AppRoutes.card),
  ];

  @override
  Widget build(BuildContext context) => Wrap(
    runSpacing: AppSpacing.sm,
    spacing: AppSpacing.sm,
    children: [for (final (icon, labelKey, route) in _actions) AppChip(icon: icon, label: context.tr(labelKey), onPressed: () => unawaited(context.push<void>(route)))],
  );
}
