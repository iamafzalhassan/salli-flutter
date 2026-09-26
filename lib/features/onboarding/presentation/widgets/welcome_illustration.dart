import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';

class WelcomeIllustration extends StatelessWidget {
  const WelcomeIllustration({super.key, required this.icon});

  static const double _coreScale = 0.42;

  static const List<double> _ringScales = [1, 0.71];

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox.square(
      dimension: AppSpacing.illustration,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final scale in _ringScales)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: colors.border, width: AppSpacing.hairline),
                shape: BoxShape.circle,
              ),
              height: AppSpacing.illustration * scale,
              width: AppSpacing.illustration * scale,
            ),
          Container(
            decoration: BoxDecoration(color: colors.accent, shape: BoxShape.circle),
            height: AppSpacing.illustration * _coreScale,
            width: AppSpacing.illustration * _coreScale,
            child: Icon(icon, color: colors.onAccent, size: AppSpacing.iconHero),
          ),
        ],
      ),
    );
  }
}
