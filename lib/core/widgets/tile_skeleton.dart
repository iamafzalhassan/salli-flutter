import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'skeleton.dart';

class TileSkeleton extends StatelessWidget {
  const TileSkeleton({super.key, this.hasLeading = true, this.subtitleLines = 1, this.crossAxisAlignment = CrossAxisAlignment.center, this.trailing});

  static const double _lastLineFactor = 0.4;
  static const double _lineFactor = 0.8;
  static const double _titleFactor = 0.6;

  final bool hasLeading;

  final int subtitleLines;

  final CrossAxisAlignment crossAxisAlignment;

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          if (hasLeading) ...[const Skeleton.circle(size: AppSpacing.touchTarget), const SizedBox(width: AppSpacing.md)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FractionallySizedBox(
                  widthFactor: _titleFactor,
                  child: Skeleton.text(textStyle: AppTextStyles.bodyStrong),
                ),
                for (var line = 0; line < subtitleLines; line++) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  FractionallySizedBox(
                    widthFactor: line == subtitleLines - 1 ? _lastLineFactor : _lineFactor,
                    child: const Skeleton.text(textStyle: AppTextStyles.caption),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: AppSpacing.md), trailing],
        ],
      ),
    );
  }
}
