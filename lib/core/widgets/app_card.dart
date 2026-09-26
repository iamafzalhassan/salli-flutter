import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';

class AppCard extends StatelessWidget {
  const AppCard({super.key, this.height, this.padding = const EdgeInsets.all(AppSpacing.cardPadding), this.margin, required this.child});

  final double? height;

  final EdgeInsetsGeometry padding;

  final EdgeInsetsGeometry? margin;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        border: Theme.of(context).brightness == Brightness.light ? Border.all(color: colors.border, width: AppSpacing.hairline) : null,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: colors.surface,
      ),
      height: height,
      margin: margin,
      padding: padding,
      child: child,
    );
  }
}
