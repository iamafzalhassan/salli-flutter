import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../localization/locale_keys.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';
import 'app_pressable.dart';

class AppKeypad extends StatefulWidget {
  const AppKeypad({super.key, this.isScrambled = false, required this.onDigit, required this.onBackspace, this.onLeading, this.leading});

  final bool isScrambled;

  final ValueChanged<int> onDigit;

  final VoidCallback onBackspace;

  final VoidCallback? onLeading;

  final Widget? leading;

  @override
  State<AppKeypad> createState() => _AppKeypadState();
}

class _AppKeypadState extends State<AppKeypad> {
  static const int _columns = 3;

  static const List<int> _ordered = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0];

  late final List<int> _digits = widget.isScrambled ? ([..._ordered]..shuffle(Random.secure())) : _ordered;

  Widget _digit(int digit, Color color) => _KeypadKey(
    onPressed: () => widget.onDigit(digit),
    child: Text('$digit', maxLines: 1, style: AppTextStyles.keypad.copyWith(color: color)),
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < _digits.length ~/ _columns; row++) Row(children: [for (final digit in _digits.sublist(row * _columns, (row + 1) * _columns)) _digit(digit, colors.textPrimary)]),
        Row(
          children: [
            _KeypadKey(onPressed: widget.onLeading, child: widget.leading ?? const SizedBox.shrink()),
            _digit(_digits.last, colors.textPrimary),
            _KeypadKey(
              onPressed: widget.onBackspace,
              child: Semantics(
                label: context.tr(LocaleKeys.commonDelete),
                child: Icon(Icons.backspace_rounded, color: colors.textSecondary, size: AppSpacing.iconMd),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeypadKey extends StatelessWidget {
  const _KeypadKey({this.onPressed, required this.child});

  final VoidCallback? onPressed;

  final Widget child;

  @override
  Widget build(BuildContext context) => Expanded(
    child: AppPressable(
      onPressed: onPressed,
      child: SizedBox(
        height: AppSpacing.keypadKey,
        child: Center(child: child),
      ),
    ),
  );
}
