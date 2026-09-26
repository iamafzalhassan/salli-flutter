import 'package:flutter/material.dart';

import '../security/screen_protection.dart';
import '../theme/app_motion.dart';
import '../theme/theme_context.dart';

class PrivacyShield extends StatefulWidget {
  const PrivacyShield({super.key, this.screenProtection, required this.child});

  final ScreenProtection? screenProtection;

  final Widget child;

  @override
  State<PrivacyShield> createState() => _PrivacyShieldState();
}

class _PrivacyShieldState extends State<PrivacyShield> with WidgetsBindingObserver {
  bool _isInBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isInBackground = state != AppLifecycleState.resumed;
    if (isInBackground != _isInBackground) setState(() => _isInBackground = isInBackground);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    builder: (context, child) {
      final isCovered = _isInBackground || (widget.screenProtection?.isCaptured ?? false);
      return Stack(
        children: [
          child!,
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !isCovered,
              child: AnimatedOpacity(
                duration: AppMotion.fast,
                opacity: isCovered ? 1 : 0,
                child: ColoredBox(color: context.colors.background),
              ),
            ),
          ),
        ],
      );
    },
    listenable: widget.screenProtection ?? const AlwaysStoppedAnimation<void>(null),
    child: widget.child,
  );
}
