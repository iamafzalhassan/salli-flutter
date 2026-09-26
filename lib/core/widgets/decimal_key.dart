import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';
import '../utils/amount_input.dart';

class DecimalKey extends StatelessWidget {
  const DecimalKey({super.key});

  @override
  Widget build(BuildContext context) => Text(AmountInput.decimalPoint, maxLines: 1, style: AppTextStyles.keypad.copyWith(color: context.colors.textPrimary));
}
