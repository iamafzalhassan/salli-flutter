import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';

class IconAvatar extends StatelessWidget {
  const IconAvatar({super.key, this.isAccent = true, this.size = AppSpacing.touchTarget, required this.icon});

  static const double _iconScale = 0.46;

  final bool isAccent;

  final double size;

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(color: isAccent ? colors.accent : colors.surfaceRaised, shape: BoxShape.circle),
      height: size,
      width: size,
      child: Icon(icon, color: isAccent ? colors.onAccent : colors.textPrimary, size: size * _iconScale),
    );
  }
}
