import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../../core/widgets/settings_toggle.dart';

class ScheduleSheet extends StatefulWidget {
  const ScheduleSheet({super.key});

  static const int lastDay = 28;

  @override
  State<ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<ScheduleSheet> {
  static const int _columns = 7;

  bool _autopay = false;

  int _day = DateTime.now().day.clamp(1, ScheduleSheet.lastDay);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.tr(LocaleKeys.billsScheduleTitle), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.xs),
        Text(context.tr(LocaleKeys.billsScheduleBody), style: AppTextStyles.body.copyWith(color: colors.textSecondary)),
        const SizedBox(height: AppSpacing.lg),
        for (var row = 0; row < ScheduleSheet.lastDay ~/ _columns; row++)
          Row(
            children: [
              for (var column = 0; column < _columns; column++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxs),
                    child: _DayCell(day: row * _columns + column + 1, isSelected: _day == row * _columns + column + 1, onPressed: (day) => setState(() => _day = day)),
                  ),
                ),
            ],
          ),
        const SizedBox(height: AppSpacing.lg),
        SettingsToggle(icon: Icons.autorenew_rounded, onChanged: (value) => setState(() => _autopay = value), subtitle: context.tr(LocaleKeys.billsAutopayBody), title: context.tr(LocaleKeys.billsAutopay), value: _autopay),
        const SizedBox(height: AppSpacing.xl),
        AppButton(label: context.tr(LocaleKeys.billsSave), onPressed: () => Navigator.of(context).pop((_day, _autopay))),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.isSelected, required this.day, required this.onPressed});

  final bool isSelected;

  final int day;

  final ValueChanged<int> onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppPressable(
      onPressed: () => onPressed(day),
      child: AspectRatio(
        aspectRatio: 1,
        child: AnimatedContainer(
          alignment: Alignment.center,
          curve: AppMotion.standard,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.sm), color: isSelected ? colors.accent : colors.surfaceRaised),
          duration: AppMotion.fast,
          child: Text(
            '$day',
            maxLines: 1,
            style: AppTextStyles.label.copyWith(color: isSelected ? colors.onAccent : colors.textPrimary, fontFeatures: AppTextStyles.tabular),
          ),
        ),
      ),
    );
  }
}
