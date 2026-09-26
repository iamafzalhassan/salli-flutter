import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_motion.dart';

class ScratchSurface extends StatefulWidget {
  const ScratchSurface({super.key, required this.coverColor, required this.child, required this.cover});

  final Color coverColor;

  final Widget child;
  final Widget cover;

  @override
  State<ScratchSurface> createState() => _ScratchSurfaceState();
}

class _ScratchSurfaceState extends State<ScratchSurface> {
  static const double _brushRadius = 24;
  static const double _revealShare = 0.5;

  static const int _grid = 12;

  final List<Offset?> _points = [];

  final Set<int> _cleared = {};

  bool _isRevealed = false;

  int _revision = 0;

  void _scratch(Offset position, Size size) {
    if (_isRevealed || size.isEmpty) return;
    final cellWidth = size.width / _grid;
    final cellHeight = size.height / _grid;
    setState(() {
      _revision++;
      _points.add(position);
      for (var row = 0; row < _grid; row++) {
        for (var column = 0; column < _grid; column++) {
          final center = Offset((column + 0.5) * cellWidth, (row + 0.5) * cellHeight);
          if ((center - position).distance <= _brushRadius) _cleared.add(row * _grid + column);
        }
      }
    });
    if (_cleared.length >= _grid * _grid * _revealShare) _reveal();
  }

  void _endStroke() {
    if (_points.isEmpty || _points.last == null) return;
    setState(() {
      _revision++;
      _points.add(null);
    });
  }

  void _reveal() {
    if (_isRevealed) return;
    unawaited(HapticFeedback.mediumImpact());
    setState(() => _isRevealed = true);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => GestureDetector(
      onHorizontalDragEnd: (_) => _endStroke(),
      onHorizontalDragStart: (details) => _scratch(details.localPosition, constraints.biggest),
      onHorizontalDragUpdate: (details) => _scratch(details.localPosition, constraints.biggest),
      onTap: _reveal,
      onVerticalDragEnd: (_) => _endStroke(),
      onVerticalDragStart: (details) => _scratch(details.localPosition, constraints.biggest),
      onVerticalDragUpdate: (details) => _scratch(details.localPosition, constraints.biggest),
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          IgnorePointer(
            child: AnimatedOpacity(
              curve: AppMotion.standard,
              duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppMotion.slow,
              opacity: _isRevealed ? 0 : 1,
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _CoverPainter(brushRadius: _brushRadius, color: widget.coverColor, points: _points, revision: _revision),
                  child: AnimatedOpacity(duration: AppMotion.fast, opacity: _points.isEmpty ? 1 : 0, child: widget.cover),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _CoverPainter extends CustomPainter {
  final double brushRadius;

  final int revision;

  final List<Offset?> points;

  final Color color;

  const _CoverPainter({required this.brushRadius, required this.revision, required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas
      ..saveLayer(bounds, Paint())
      ..drawRect(bounds, Paint()..color = color);
    final eraser = Paint()
      ..blendMode = BlendMode.clear
      ..strokeCap = StrokeCap.round
      ..strokeWidth = brushRadius * 2
      ..style = PaintingStyle.stroke;
    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      if (point == null) continue;
      final next = index + 1 < points.length ? points[index + 1] : null;
      if (next != null) {
        canvas.drawLine(point, next, eraser);
      } else {
        canvas.drawCircle(point, brushRadius, Paint()..blendMode = BlendMode.clear);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CoverPainter oldDelegate) => oldDelegate.revision != revision || oldDelegate.color != color;
}
