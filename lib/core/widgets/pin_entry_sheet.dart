import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../localization/locale_keys.dart';
import '../security/pin_policy.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';
import 'app_button.dart';
import 'app_keypad.dart';
import 'pin_dots.dart';

class PinEntrySheet extends StatefulWidget {
  const PinEntrySheet({super.key, required this.body, required this.title});

  final String body;
  final String title;

  @override
  State<PinEntrySheet> createState() => _PinEntrySheetState();
}

class _PinEntrySheetState extends State<PinEntrySheet> {
  bool _isClosing = false;

  String _pin = '';

  bool get _isComplete => _pin.length == PinPolicy.length;

  void _backspace() {
    if (!_isClosing && _pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _digitEntered(int digit) async {
    if (_isClosing || _isComplete) return;
    setState(() => _pin = '$_pin$digit');
    if (!_isComplete) return;
    await Future<void>.delayed(AppMotion.fast);
    _confirm();
  }

  void _confirm() {
    if (!mounted || _isClosing || !_isComplete) return;
    _isClosing = true;
    Navigator.of(context).pop(_pin);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.title),
      const SizedBox(height: AppSpacing.sm),
      Text(widget.body, style: AppTextStyles.body.copyWith(color: context.colors.textSecondary)),
      const SizedBox(height: AppSpacing.xl),
      PinDots(filled: _pin.length, hasError: false, length: PinPolicy.length),
      const SizedBox(height: AppSpacing.xl),
      AppKeypad(onBackspace: _backspace, onDigit: (digit) => unawaited(_digitEntered(digit))),
      const SizedBox(height: AppSpacing.lg),
      AppButton(isLoading: _isClosing, label: context.tr(LocaleKeys.commonConfirm), onPressed: _isComplete ? _confirm : null),
    ],
  );
}
