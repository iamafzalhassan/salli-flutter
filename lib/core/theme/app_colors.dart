import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  static const AppColors dark = AppColors(
    accent: Color(0xFFE7FF5F),
    accentInk: Color(0xFFE7FF5F),
    background: Color(0xFF030301),
    border: Color(0xFF2A2A27),
    danger: Color(0xFFF87171),
    onAccent: Color(0xFF030301),
    success: Color(0xFF4ADE80),
    surface: Color(0xFF161615),
    surfaceRaised: Color(0xFF1F1F1D),
    textPrimary: Color(0xFFFAFAFA),
    textSecondary: Color(0xFF9A9696),
    warning: Color(0xFFFBBF24),
  );
  static const AppColors light = AppColors(
    accent: Color(0xFFE7FF5F),
    accentInk: Color(0xFF5B6B00),
    background: Color(0xFFF5F5F0),
    border: Color(0xFFE2E2DA),
    danger: Color(0xFFB91C1C),
    onAccent: Color(0xFF030301),
    success: Color(0xFF15803D),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFEDEDE7),
    textPrimary: Color(0xFF030301),
    textSecondary: Color(0xFF6B6868),
    warning: Color(0xFFB45309),
  );

  final Color accent;
  final Color accentInk;
  final Color background;
  final Color border;
  final Color danger;
  final Color onAccent;
  final Color success;
  final Color surface;
  final Color surfaceRaised;
  final Color textPrimary;
  final Color textSecondary;
  final Color warning;

  const AppColors({
    required this.accent,
    required this.accentInk,
    required this.background,
    required this.border,
    required this.danger,
    required this.onAccent,
    required this.success,
    required this.surface,
    required this.surfaceRaised,
    required this.textPrimary,
    required this.textSecondary,
    required this.warning,
  });

  @override
  AppColors copyWith({Color? accent, Color? accentInk, Color? background, Color? border, Color? danger, Color? onAccent, Color? success, Color? surface, Color? surfaceRaised, Color? textPrimary, Color? textSecondary, Color? warning}) =>
      AppColors(
        accent: accent ?? this.accent,
        accentInk: accentInk ?? this.accentInk,
        background: background ?? this.background,
        border: border ?? this.border,
        danger: danger ?? this.danger,
        onAccent: onAccent ?? this.onAccent,
        success: success ?? this.success,
        surface: surface ?? this.surface,
        surfaceRaised: surfaceRaised ?? this.surfaceRaised,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        warning: warning ?? this.warning,
      );

  @override
  AppColors lerp(AppColors? other, double t) => other == null
      ? this
      : AppColors(
          accent: Color.lerp(accent, other.accent, t)!,
          accentInk: Color.lerp(accentInk, other.accentInk, t)!,
          background: Color.lerp(background, other.background, t)!,
          border: Color.lerp(border, other.border, t)!,
          danger: Color.lerp(danger, other.danger, t)!,
          onAccent: Color.lerp(onAccent, other.onAccent, t)!,
          success: Color.lerp(success, other.success, t)!,
          surface: Color.lerp(surface, other.surface, t)!,
          surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
          textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
          textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
          warning: Color.lerp(warning, other.warning, t)!,
        );
}
