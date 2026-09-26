import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../errors/failure.dart';
import '../errors/failure_codes.dart';
import '../localization/locale_keys.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';
import '../utils/amount_input.dart';
import '../utils/money.dart';
import 'app_button.dart';
import 'app_keypad.dart';
import 'decimal_key.dart';
import 'failure_text.dart';

class AmountSheet extends StatefulWidget {
  const AmountSheet({super.key, required this.confirmLabel, required this.title, this.initial, this.limit});

  final String confirmLabel;
  final String title;

  final Money? initial;
  final Money? limit;

  @override
  State<AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<AmountSheet> {
  late AmountInput _input = widget.initial == null ? const AmountInput() : AmountInput.of(widget.initial!);

  bool get _isAboveLimit {
    final limit = widget.limit;
    return limit != null && _input.money > limit;
  }

  void _update(AmountInput input) => setState(() => _input = input);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final money = _input.money;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.xl),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: AnimatedSwitcher(
            duration: AppMotion.fast,
            child: Text(
              '${context.tr(LocaleKeys.currencySymbol)} ${_input.display}',
              key: ValueKey(_input),
              maxLines: 1,
              style: AppTextStyles.balance.copyWith(color: _input.isEmpty ? colors.textSecondary : colors.textPrimary),
            ),
          ),
        ),
        FailureText(failure: _isAboveLimit ? const Failure(FailureCodes.limitExceeded) : null, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.lg),
        AppKeypad(leading: const DecimalKey(), onBackspace: () => _update(_input.backspace()), onDigit: (digit) => _update(_input.append(digit)), onLeading: () => _update(_input.addDecimalPoint())),
        const SizedBox(height: AppSpacing.md),
        AppButton(label: widget.confirmLabel, onPressed: money.isPositive && !_isAboveLimit ? () => Navigator.of(context).pop(money) : null),
      ],
    );
  }
}
