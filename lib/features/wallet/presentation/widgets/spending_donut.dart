import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_motion.dart';

class SpendingDonut extends StatelessWidget {
  const SpendingDonut({super.key, required this.strokeWidth, required this.segments, required this.trackColor});

  final double strokeWidth;

  final List<({Color color, double fraction})> segments;

  final Color trackColor;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: TweenAnimationBuilder<double>(
      builder: (context, progress, _) => CustomPaint(
        painter: _DonutPainter(progress: progress, segments: segments, strokeWidth: strokeWidth, trackColor: trackColor),
        size: Size.infinite,
      ),
      curve: AppMotion.emphasized,
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppMotion.hero,
      tween: Tween<double>(begin: 0, end: 1),
    ),
  );
}

class _DonutPainter extends CustomPainter {
  static const double _fullTurn = 2 * pi;
  static const double _gap = 0.04;
  static const double _start = -pi / 2;

  final double progress;
  final double strokeWidth;

  final List<({Color color, double fraction})> segments;

  final Color trackColor;

  const _DonutPainter({required this.progress, required this.strokeWidth, required this.segments, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: (size.shortestSide - strokeWidth) / 2);
    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawArc(rect, 0, _fullTurn, false, paint..color = trackColor);
    final gap = segments.length > 1 ? _gap : 0;
    var start = _start;
    for (final segment in segments) {
      final sweep = segment.fraction * _fullTurn * progress;
      if (sweep > gap) canvas.drawArc(rect, start, sweep - gap, false, paint..color = segment.color);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.strokeWidth != strokeWidth || oldDelegate.segments != segments || oldDelegate.trackColor != trackColor;
}
