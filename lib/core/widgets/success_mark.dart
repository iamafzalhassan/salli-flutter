import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';

class SuccessMark extends StatefulWidget {
  const SuccessMark({super.key, this.size = AppSpacing.successMark});

  final double size;

  @override
  State<SuccessMark> createState() => _SuccessMarkState();
}

class _SuccessMarkState extends State<SuccessMark> with SingleTickerProviderStateMixin {
  static const double _durationScale = 1.5;

  static const Interval _checkInterval = Interval(0.4, 1, curve: AppMotion.standard);
  static const Interval _circleInterval = Interval(0, 0.55, curve: AppMotion.spring);

  late final AnimationController _controller = AnimationController(duration: AppMotion.hero * _durationScale, vsync: this);

  late final CurvedAnimation _check = CurvedAnimation(curve: _checkInterval, parent: _controller);
  late final CurvedAnimation _circle = CurvedAnimation(curve: _circleInterval, parent: _controller);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      unawaited(HapticFeedback.heavyImpact());
      unawaited(_controller.forward());
    }
  }

  @override
  void dispose() {
    _check.dispose();
    _circle.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox.square(
      dimension: widget.size,
      child: ScaleTransition(
        scale: _circle,
        child: DecoratedBox(
          decoration: BoxDecoration(color: colors.accent, shape: BoxShape.circle),
          child: CustomPaint(
            painter: _CheckPainter(color: colors.onAccent, progress: _check),
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  static const double _strokeScale = 0.075;

  static const List<Offset> _points = [Offset(0.3, 0.52), Offset(0.44, 0.66), Offset(0.71, 0.38)];

  final Animation<double> progress;

  final Color color;

  _CheckPainter({required this.progress, required this.color}) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(_points.first.dx * size.width, _points.first.dy * size.height);
    for (final point in _points.skip(1)) {
      path.lineTo(point.dx * size.width, point.dy * size.height);
    }
    final metric = path.computeMetrics().first;
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.width * _strokeScale
      ..style = PaintingStyle.stroke;
    canvas.drawPath(metric.extractPath(0, metric.length * progress.value), paint);
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) => oldDelegate.color != color;
}
