import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../utils/lkr_format.dart';
import '../utils/money.dart';

class AnimatedMoney extends StatelessWidget {
  const AnimatedMoney({super.key, this.isHidden = false, required this.symbol, required this.money, required this.style});

  static const String _mask = '••••••';

  final bool isHidden;

  final String symbol;

  final Money money;

  final TextStyle style;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<int>(
    builder: (context, cents, child) => FittedBox(
      alignment: Alignment.centerLeft,
      fit: BoxFit.scaleDown,
      child: Text(isHidden ? '$symbol $_mask' : LkrFormat.withSymbol(Money(cents), symbol), maxLines: 1, style: style),
    ),
    curve: AppMotion.emphasized,
    duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppMotion.hero,
    tween: IntTween(begin: 0, end: money.cents),
  );
}
