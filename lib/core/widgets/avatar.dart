import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';

class Avatar extends StatelessWidget {
  const Avatar({super.key, this.size = AppSpacing.touchTarget, this.name});

  static const double _iconScale = 0.5;
  static const double _initialsScale = 0.38;

  static const int _maxInitials = 2;

  static final RegExp _whitespace = RegExp(r'\s+');

  final double size;

  final String? name;

  static String _initialsOf(String? name) => [for (final word in (name ?? '').trim().split(_whitespace).where((word) => word.isNotEmpty).take(_maxInitials)) word.characters.first.toUpperCase()].join();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final initials = _initialsOf(name);
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(color: colors.accent, shape: BoxShape.circle),
      height: size,
      width: size,
      child: initials.isEmpty
          ? Icon(Icons.person_rounded, color: colors.onAccent, size: size * _iconScale)
          : Text(
              initials,
              maxLines: 1,
              style: AppTextStyles.bodyStrong.copyWith(color: colors.onAccent, fontSize: size * _initialsScale),
            ),
    );
  }
}
