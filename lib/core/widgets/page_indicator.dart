import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';

class PageIndicator extends StatelessWidget {
  const PageIndicator({super.key, required this.position, required this.count});

  final double position;

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < count; index++)
          Builder(
            builder: (context) {
              final focus = (1 - (position - index).abs()).clamp(0.0, 1.0);
              return Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.pill), color: Color.lerp(colors.border, colors.accent, focus)),
                height: AppSpacing.sm,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                width: lerpDouble(AppSpacing.sm, AppSpacing.xl, focus),
              );
            },
          ),
      ],
    );
  }
}
