import 'package:flutter/material.dart';
import '../config/safety_config.dart';
import '../theme/app_colors.dart';
import 'safety_signal.dart';

/// Represents the calculated safety score and rationale breakdown for a walking route candidate.
class SafetyScore {
  final int overallScore; // 0 to 100
  final double hazardPenalty;
  final double recencyPenalty;
  final double proximityPenalty;
  final double densityPenalty;
  final double distancePenalty;
  final double historicalPenalty;
  final double osmInfrastructureBonus;
  final double osmContextualBonus;
  final double confidence;
  final List<SafetySignal> signals;
  final List<String> whyBulletPoints;

  const SafetyScore({
    required this.overallScore,
    required this.hazardPenalty,
    required this.recencyPenalty,
    required this.proximityPenalty,
    required this.densityPenalty,
    required this.distancePenalty,
    this.historicalPenalty = 0.0,
    this.osmInfrastructureBonus = 0.0,
    this.osmContextualBonus = 0.0,
    required this.confidence,
    required this.signals,
    required this.whyBulletPoints,
  });

  /// Standard disclaimer requirement.
  static const String disclaimer = SafetyConfig.trustSystemDisclaimer;

  /// Get color corresponding to safety score range.
  Color get badgeColor {
    if (overallScore >= 80) return AppColors.primary; // Emerald green (High safety)
    if (overallScore >= 60) return AppColors.warning; // Amber (Moderate)
    return AppColors.danger; // Alert Coral (Higher risk signals)
  }

  /// Get user-friendly label description.
  String get safetyLabel {
    if (overallScore >= 80) return 'Safety-oriented route';
    if (overallScore >= 60) return 'Moderate reported risk';
    return 'Higher reported risk signals';
  }
}
