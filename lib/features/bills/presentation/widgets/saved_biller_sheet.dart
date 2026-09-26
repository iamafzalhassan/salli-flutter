import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/icon_avatar.dart';
import '../../domain/entities/saved_biller.dart';

enum SavedBillerAction { pay, remove, rename, schedule, unschedule }

class SavedBillerSheet extends StatelessWidget {
  const SavedBillerSheet({super.key, required this.hasSchedule, required this.saved});

  static const String _separator = ' · ';

  final bool hasSchedule;

  final SavedBiller saved;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final actions = [
      (SavedBillerAction.pay, Icons.payments_rounded, LocaleKeys.billsPayNow),
      (SavedBillerAction.rename, Icons.edit_rounded, LocaleKeys.billsRename),
      if (hasSchedule) (SavedBillerAction.unschedule, Icons.event_busy_rounded, LocaleKeys.billsCancelSchedule) else (SavedBillerAction.schedule, Icons.event_repeat_rounded, LocaleKeys.billsSchedule),
      (SavedBillerAction.remove, Icons.delete_outline_rounded, LocaleKeys.billsRemove),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(saved.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          [saved.biller.name, saved.accountNumber].join(_separator),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.label.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final (action, icon, labelKey) in actions)
          AppListTile(
            leading: IconAvatar(icon: icon, isAccent: false),
            onPressed: () => Navigator.of(context).pop(action),
            title: context.tr(labelKey),
            trailing: const SizedBox.shrink(),
          ),
      ],
    );
  }
}
