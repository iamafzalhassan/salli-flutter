import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/lkr_format.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../domain/entities/transaction_filter.dart';
import '../../domain/entities/transaction_type.dart';

class TransactionFilterSheet extends StatefulWidget {
  const TransactionFilterSheet({super.key, required this.filter});

  final TransactionFilter filter;

  @override
  State<TransactionFilterSheet> createState() => _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<TransactionFilterSheet> {
  static const double _maxHeightScale = 0.6;

  static const List<(Money?, Money?)> _amountRanges = [(null, Money.rupees(1000)), (Money.rupees(1000), Money.rupees(10000)), (Money.rupees(10000), null)];

  static const List<int> _periodDays = [7, 30, 90];

  static final List<TransactionType> _types = [
    for (final type in TransactionType.values)
      if (type != TransactionType.other) type,
  ];

  late Set<TransactionType> _selectedTypes = {...widget.filter.types};

  late int? _days = _initialDays();

  late (Money?, Money?)? _amountRange = _amountRanges.where((range) => range.$1 == widget.filter.min && range.$2 == widget.filter.max).firstOrNull;

  int? _initialDays() {
    final from = widget.filter.from;
    if (from == null) return null;
    final days = DateUtils.dateOnly(DateTime.now()).difference(DateUtils.dateOnly(from)).inDays;
    return _periodDays.contains(days) ? days : null;
  }

  void _toggleType(TransactionType type) => setState(() => _selectedTypes = _selectedTypes.contains(type) ? ({..._selectedTypes}..remove(type)) : {..._selectedTypes, type});

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.lg),
    child: Text(text.toUpperCase(), maxLines: 1, style: AppTextStyles.overline.copyWith(color: context.colors.textSecondary)),
  );

  String _rangeLabel((Money?, Money?) range, String symbol) => switch (range) {
    (null, final Money max) => context.tr(LocaleKeys.activityFilterAmountUnder, args: [LkrFormat.withSymbol(max, symbol)]),
    (final Money min, null) => context.tr(LocaleKeys.activityFilterAmountOver, args: [LkrFormat.withSymbol(min, symbol)]),
    (final Money min, final Money max) => context.tr(LocaleKeys.activityFilterAmountBetween, args: [LkrFormat.withSymbol(min, symbol), LkrFormat.withSymbol(max, symbol)]),
    _ => context.tr(LocaleKeys.activityFilterAny),
  };

  void _reset() => setState(() {
    _amountRange = null;
    _days = null;
    _selectedTypes = {};
  });

  void _apply() {
    final days = _days;
    final range = _amountRange;
    Navigator.of(context).pop(
      widget.filter.copyWith(
        from: () => days == null ? null : DateUtils.dateOnly(DateTime.now()).subtract(Duration(days: days)),
        max: () => range?.$2,
        min: () => range?.$1,
        to: () => null,
        types: _selectedTypes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final symbol = context.tr(LocaleKeys.currencySymbol);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.tr(LocaleKeys.activityFilterTitle), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.title),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * _maxHeightScale),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _label(context.tr(LocaleKeys.activityFilterType)),
                Wrap(
                  runSpacing: AppSpacing.sm,
                  spacing: AppSpacing.sm,
                  children: [for (final type in _types) AppChip(isSelected: _selectedTypes.contains(type), label: context.tr('${LocaleKeys.transactionPrefix}.${type.name}'), onPressed: () => _toggleType(type))],
                ),
                _label(context.tr(LocaleKeys.activityFilterPeriod)),
                Wrap(
                  runSpacing: AppSpacing.sm,
                  spacing: AppSpacing.sm,
                  children: [
                    AppChip(isSelected: _days == null, label: context.tr(LocaleKeys.activityFilterAny), onPressed: () => setState(() => _days = null)),
                    for (final days in _periodDays)
                      AppChip(
                        isSelected: _days == days,
                        label: context.tr(LocaleKeys.activityFilterPeriodDays, args: ['$days']),
                        onPressed: () => setState(() => _days = days),
                      ),
                  ],
                ),
                _label(context.tr(LocaleKeys.activityFilterAmount)),
                Wrap(
                  runSpacing: AppSpacing.sm,
                  spacing: AppSpacing.sm,
                  children: [
                    AppChip(isSelected: _amountRange == null, label: context.tr(LocaleKeys.activityFilterAny), onPressed: () => setState(() => _amountRange = null)),
                    for (final range in _amountRanges) AppChip(isSelected: _amountRange == range, label: _rangeLabel(range, symbol), onPressed: () => setState(() => _amountRange = range)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: AppButton(label: context.tr(LocaleKeys.activityClearFilters), onPressed: _reset, variant: AppButtonVariant.secondary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton(label: context.tr(LocaleKeys.activityFilterApply), onPressed: _apply),
            ),
          ],
        ),
      ],
    );
  }
}
