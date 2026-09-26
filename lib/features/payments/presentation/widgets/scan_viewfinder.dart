import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';

class ScanViewfinder extends StatefulWidget {
  const ScanViewfinder({super.key, required this.window});

  final Rect window;

  @override
  State<ScanViewfinder> createState() => _ScanViewfinderState();
}

class _ScanViewfinderState extends State<ScanViewfinder> with SingleTickerProviderStateMixin {
  static const double _scrimOpacity = 0.72;

  late final AnimationController _controller = AnimationController(duration: AppMotion.breath, vsync: this);

  late final CurvedAnimation _pulse = CurvedAnimation(curve: AppMotion.breathing, parent: _controller);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return RepaintBoundary(
      child: CustomPaint(
        painter: _ViewfinderPainter(
          cornerColor: colors.accent,
          pulse: _pulse,
          scrimColor: colors.background.withValues(alpha: _scrimOpacity),
          window: widget.window,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  static const double _cornerScale = 0.16;

  static const int _corners = 4;

  final Animation<double> pulse;

  final Color cornerColor;
  final Color scrimColor;

  final Rect window;

  _ViewfinderPainter({required this.pulse, required this.cornerColor, required this.scrimColor, required this.window}) : super(repaint: pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(window, const Radius.circular(AppRadius.lg)));
    canvas.drawPath(scrim, Paint()..color = scrimColor);
    final half = window.width / 2 + AppSpacing.xs * pulse.value;
    final length = window.width * _cornerScale;
    final corner = Path()
      ..moveTo(-half, -half + length)
      ..lineTo(-half, -half + AppRadius.lg)
      ..arcToPoint(Offset(-half + AppRadius.lg, -half), radius: const Radius.circular(AppRadius.lg))
      ..lineTo(-half + length, -half);
    final paint = Paint()
      ..color = cornerColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = AppSpacing.xs
      ..style = PaintingStyle.stroke;
    canvas
      ..save()
      ..translate(window.center.dx, window.center.dy);
    for (var index = 0; index < _corners; index++) {
      canvas
        ..drawPath(corner, paint)
        ..rotate(pi / 2);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ViewfinderPainter oldDelegate) => oldDelegate.cornerColor != cornerColor || oldDelegate.scrimColor != scrimColor || oldDelegate.window != window;
}
