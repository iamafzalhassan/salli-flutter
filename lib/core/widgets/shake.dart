import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';

class Shake extends StatefulWidget {
  const Shake({super.key, required this.trigger, required this.child});

  final int trigger;

  final Widget child;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  static const double _amplitude = AppSpacing.md;
  static const double _oscillations = 4;

  late final AnimationController _controller = AnimationController(duration: AppMotion.slow, vsync: this);

  @override
  void didUpdateWidget(covariant Shake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger == oldWidget.trigger) return;
    unawaited(HapticFeedback.heavyImpact());
    unawaited(_controller.forward(from: 0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) => Transform.translate(offset: Offset(sin(_controller.value * pi * _oscillations) * _amplitude * (1 - _controller.value), 0), child: child),
    child: widget.child,
  );
}
