import 'package:flutter/widgets.dart';

/// Spacing and radius tokens — mirrors the shadcn scale.
abstract final class MasterySpacing {
  // Spacing scale
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  // Screen insets
  static const EdgeInsets screen = EdgeInsets.fromLTRB(xl, xl, xl, xxl);

  // Border radii
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 18;
}
