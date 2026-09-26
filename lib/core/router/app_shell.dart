import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../localization/locale_keys.dart';
import '../widgets/salli_nav_bar.dart';
import 'app_routes.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  static const List<(IconData, String)> _destinations = [
    (Icons.home_rounded, LocaleKeys.navHome),
    (Icons.receipt_long_rounded, LocaleKeys.navActivity),
    (Icons.redeem_rounded, LocaleKeys.navRewards),
    (Icons.person_rounded, LocaleKeys.navProfile),
  ];

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        navigationShell,
        Align(
          alignment: Alignment.bottomCenter,
          child: SalliNavBar(
            currentIndex: navigationShell.currentIndex,
            items: [for (final (icon, labelKey) in _destinations) SalliNavItem(icon: icon, label: context.tr(labelKey))],
            onScan: () => unawaited(context.push<void>(AppRoutes.scan)),
            onSelected: (index) => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
            scanLabel: context.tr(LocaleKeys.navScan),
          ),
        ),
      ],
    ),
  );
}
