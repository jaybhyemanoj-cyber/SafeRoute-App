import 'package:flutter/material.dart';

class AppSpacing {
  // Spacing Tokens
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  // Radius Tokens
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 99.0;

  // BorderRadius Helper Objects
  static const BorderRadius roundedSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius roundedLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius roundedXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius roundedSheet = BorderRadius.only(
    topLeft: Radius.circular(radiusXl),
    topRight: Radius.circular(radiusXl),
  );

  // Dimension Constants
  static const double buttonHeight = 54.0;
  static const double iconButtonSize = 48.0;
  static const double searchBarHeight = 56.0;
  static const double cardPadding = 20.0;
}
