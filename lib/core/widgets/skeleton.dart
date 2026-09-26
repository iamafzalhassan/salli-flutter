import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/theme_context.dart';

class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.radius = AppRadius.sm, required double this.height, this.width}) : textStyle = null;

  const Skeleton.circle({super.key, required double size}) : height = size, radius = AppRadius.pill, textStyle = null, width = size;

  const Skeleton.text({super.key, required TextStyle this.textStyle, this.width = double.infinity}) : height = null, radius = AppRadius.xs;

  static const String _lineGlyph = ' ';

  final double radius;

  final double? height;
  final double? width;

  final TextStyle? textStyle;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(duration: AppMotion.breath, lowerBound: AppMotion.skeletonMinOpacity, vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = widget.textStyle;
    return ExcludeSemantics(
      child: FadeTransition(
        opacity: _controller,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(widget.radius), color: context.colors.surfaceRaised),
          height: widget.height,
          width: widget.width,
          child: textStyle == null ? null : Text(Skeleton._lineGlyph, maxLines: 1, style: textStyle),
        ),
      ),
    );
  }
}
