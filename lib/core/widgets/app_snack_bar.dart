import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';

void showAppSnackBar(BuildContext context, String message) {
  final colors = context.colors;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: colors.surfaceRaised,
        behavior: SnackBarBehavior.floating,
        content: Text(message, style: AppTextStyles.label.copyWith(color: colors.textPrimary)),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
}
