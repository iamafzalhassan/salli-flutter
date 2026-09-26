import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/lkr_format.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/category_icons.dart';
import '../../../../core/widgets/icon_avatar.dart';
import '../../domain/entities/offer.dart';

class OfferTile extends StatelessWidget {
  const OfferTile({super.key, required this.offer});

  static const int _percent = 100;

  final Offer offer;

  @override
  Widget build(BuildContext context) {
    final symbol = context.tr(LocaleKeys.currencySymbol);
    final percent = NumberFormat.percentPattern(context.locale.toLanguageTag()).format(offer.cashbackPercent / _percent);
    return AppListTile(
      leading: IconAvatar(icon: CategoryIcons.of(offer.merchant.category.name), isAccent: false),
      subtitle: context.tr(LocaleKeys.rewardsOfferTerms, namedArgs: {'max': LkrFormat.withSymbol(offer.maxCashback, symbol), 'min': LkrFormat.withSymbol(offer.minSpend, symbol), 'percent': percent}),
      title: offer.merchant.name,
      trailing: offer.isUsed
          ? Text(context.tr(LocaleKeys.rewardsOfferUsed), maxLines: 1, style: AppTextStyles.caption.copyWith(color: context.colors.textSecondary))
          : AppChip(
              label: context.tr(LocaleKeys.rewardsPayHere),
              onPressed: () => unawaited(context.push<void>(AppRoutes.payAmount, extra: offer.recipient)),
            ),
    );
  }
}
