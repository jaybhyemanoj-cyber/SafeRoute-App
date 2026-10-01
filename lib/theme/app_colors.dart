import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Color (Deep Emerald / Modern Safety Green)
  static const Color primary = Color(0xFF059669);
  static const Color primaryDark = Color(0xFF047857);
  static const Color primaryLight = Color(0xFF10B981);
  static const Color primaryContainer = Color(0xFFD1FAE5);

  // Background Colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color inputBackground = Color(0xFFF1F5F9);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status & Accents
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);

  // UI Accents
  static const Color divider = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFCBD5E1);
  static const Color activePulse = Color(0x33059669);

  // Route Polyline
  static const Color routePolyline = Color(0xFF059669);
  static const Color routePolylineOutline = Color(0xFF047857);

  // Shadows
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 16,
      spreadRadius: 0,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 6,
      spreadRadius: 0,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 24,
      spreadRadius: 0,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 8,
      spreadRadius: 0,
      offset: Offset(0, 2),
    ),
  ];
}
