import 'package:flutter/widgets.dart';

abstract final class AppTextStyles {
  static const double maxTextScale = 1.3;

  static const String fontFamily = 'SFProDisplay';

  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  static const TextStyle amount = TextStyle(fontFamily: fontFamily, fontFeatures: tabular, fontSize: 16, fontWeight: FontWeight.w600);
  static const TextStyle balance = TextStyle(fontFamily: fontFamily, fontFeatures: tabular, fontSize: 39, fontWeight: FontWeight.w600, height: 1.1, letterSpacing: -0.5);
  static const TextStyle body = TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w400, height: 1.4);
  static const TextStyle bodyStrong = TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600);
  static const TextStyle caption = TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w400);
  static const TextStyle headline = TextStyle(fontFamily: fontFamily, fontSize: 24, fontWeight: FontWeight.w600, height: 1.2);
  static const TextStyle keypad = TextStyle(fontFamily: fontFamily, fontFeatures: tabular, fontSize: 28, fontWeight: FontWeight.w500);
  static const TextStyle label = TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w500);
  static const TextStyle overline = TextStyle(fontFamily: fontFamily, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8);
  static const TextStyle title = TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w600);
}
