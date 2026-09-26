import 'package:flutter/animation.dart';

abstract final class AppMotion {
  static const double breathScale = 1.06;
  static const double disabledOpacity = 0.4;
  static const double pressedScale = 0.96;
  static const double skeletonMinOpacity = 0.45;

  static const AnimationStyle sheet = AnimationStyle(curve: emphasized, duration: slow, reverseCurve: exit, reverseDuration: base);

  static const Curve breathing = Curves.easeInOut;
  static const Curve emphasized = Curves.easeOutQuint;
  static const Curve exit = Curves.easeInCubic;
  static const Curve spring = Curves.easeOutBack;
  static const Curve standard = Curves.easeOutCubic;

  static const Duration base = Duration(milliseconds: 250);
  static const Duration breath = Duration(milliseconds: 1600);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration hero = Duration(milliseconds: 600);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration stagger = Duration(milliseconds: 45);

  static const Offset entranceOffset = Offset(0, 0.12);
  static const Offset pageSlide = Offset(0.06, 0);
}
