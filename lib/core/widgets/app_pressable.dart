import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_motion.dart';

class AppPressable extends StatefulWidget {
  const AppPressable({super.key, this.curve = AppMotion.standard, this.onPressed, required this.child});

  final Curve curve;

  final VoidCallback? onPressed;

  final Widget child;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _isPressed = false;

  bool get _isEnabled => widget.onPressed != null;

  void _handleTap() {
    unawaited(HapticFeedback.selectionClick());
    widget.onPressed?.call();
  }

  void _setPressed(bool value) {
    if (_isPressed != value) setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(
      button: true,
      enabled: _isEnabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _isEnabled ? _handleTap : null,
        onTapCancel: () => _setPressed(false),
        onTapDown: _isEnabled ? (_) => _setPressed(true) : null,
        onTapUp: (_) => _setPressed(false),
        child: AnimatedScale(curve: widget.curve, duration: AppMotion.fast, scale: _isPressed ? AppMotion.pressedScale : 1, child: widget.child),
      ),
    ),
  );
}
