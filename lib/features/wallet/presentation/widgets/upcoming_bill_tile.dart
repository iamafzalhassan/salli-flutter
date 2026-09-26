import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/date_labels.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/lkr_format.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/category_icons.dart';
import '../../../../core/widgets/icon_avatar.dart';
import '../../../bills/domain/entities/bill_account_draft.dart';
import '../../../bills/domain/entities/bill_schedule.dart';

class UpcomingBillTile extends StatelessWidget {
  const UpcomingBillTile({super.key, required this.schedule});

  static const String _separator = ' · ';

  final BillSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final amountDue = schedule.amountDue;
    final date = context.dayLabel(schedule.nextRunAt);
    return AppListTile(
      leading: IconAvatar(icon: CategoryIcons.of(schedule.savedBiller.biller.category.name)),
      onPressed: () => unawaited(context.push<void>(AppRoutes.billAccount, extra: BillAccountDraft.saved(schedule.savedBiller))),
      subtitle: [
        if (amountDue != null && amountDue.isPositive) LkrFormat.withSymbol(amountDue, context.tr(LocaleKeys.currencySymbol)),
        context.tr(schedule.autopay ? LocaleKeys.billsAutopayOn : LocaleKeys.billsReminderOn, args: [date]),
      ].join(_separator),
      title: schedule.savedBiller.displayName,
    );
  }
}
