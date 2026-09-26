import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static final ThemeData dark = _build(Brightness.dark, AppColors.dark);
  static final ThemeData light = _build(Brightness.light, AppColors.light);

  static ThemeData _build(Brightness brightness, AppColors colors) => ThemeData(
    appBarTheme: AppBarTheme(backgroundColor: colors.background, elevation: 0, foregroundColor: colors.textPrimary, scrolledUnderElevation: 0, surfaceTintColor: Colors.transparent, systemOverlayStyle: _overlayStyle(brightness, colors)),
    brightness: brightness,
    colorScheme: ColorScheme(
      brightness: brightness,
      error: colors.danger,
      onError: colors.background,
      onPrimary: colors.onAccent,
      onSecondary: colors.onAccent,
      onSurface: colors.textPrimary,
      primary: colors.accent,
      secondary: colors.accent,
      surface: colors.surface,
    ),
    extensions: [colors],
    fontFamily: AppTextStyles.fontFamily,
    highlightColor: Colors.transparent,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {TargetPlatform.android: PredictiveBackPageTransitionsBuilder(), TargetPlatform.iOS: CupertinoPageTransitionsBuilder()}),
    scaffoldBackgroundColor: colors.background,
    splashFactory: NoSplash.splashFactory,
    textSelectionTheme: TextSelectionThemeData(cursorColor: colors.accentInk, selectionColor: colors.accent.withValues(alpha: 0.4), selectionHandleColor: colors.accentInk),
    textTheme: const TextTheme().apply(bodyColor: colors.textPrimary, displayColor: colors.textPrimary),
  );

  static SystemUiOverlayStyle _overlayStyle(Brightness brightness, AppColors colors) => SystemUiOverlayStyle(
    statusBarBrightness: brightness,
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
    systemNavigationBarColor: colors.background,
    systemNavigationBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
  );
}
