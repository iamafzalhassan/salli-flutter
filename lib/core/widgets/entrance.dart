import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

class Entrance extends StatefulWidget {
  const Entrance({super.key, this.index = 0, required this.child});

  final int index;

  final Widget child;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance> with SingleTickerProviderStateMixin {
  late final Animation<Offset> _slide = Tween<Offset>(begin: AppMotion.entranceOffset, end: Offset.zero).animate(_curve);

  late final AnimationController _controller = AnimationController(duration: AppMotion.slow, vsync: this);

  late final CurvedAnimation _curve = CurvedAnimation(curve: AppMotion.emphasized, parent: _controller);

  Timer? _delay;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.value > 0 || _delay != null) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _delay = Timer(AppMotion.stagger * widget.index, () => unawaited(_controller.forward()));
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _curve,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}
