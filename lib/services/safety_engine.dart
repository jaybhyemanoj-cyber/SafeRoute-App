import 'package:latlong2/latlong.dart';
import '../config/safety_config.dart';
import '../models/hazard_report.dart';
import '../models/route_model.dart';
import '../models/safety_score.dart';
import '../models/safety_signal.dart';
import '../models/user_preferences.dart';
import 'hazard_analysis_service.dart';

/// Centralized Safety Analysis Engine for calculating transparent route safety scores (Phase 3 & Phase 6).
class SafetyEngine {
  /// Calculate SafetyScore for a candidate route against nearby community hazard reports and optional user preferences.
  static SafetyScore calculateScore({
    required RouteModel route,
    required List<HazardReport> nearbyReports,
    double minRouteDistanceMeters = 0,
    UserPreferences? preferences,
  }) {
    double totalHazardPenalty = 0.0;
    double totalRecencySubPenalty = 0.0;
    double totalProximitySubPenalty = 0.0;
    double totalDensitySubPenalty = 0.0;
    final List<SafetySignal> detectedSignals = [];
    final List<String> whyBullets = [];

    // Group reports by category for density capping
    final clusters = HazardAnalysisService.clusterReportsByCategory(nearbyReports);

    clusters.forEach((categoryKey, reports) {
      double basePenalty = SafetyConfig.hazardWeights[categoryKey] ?? 5.0;

      // Apply personalized hazard avoidance preference weight if set
      if (preferences != null && preferences.isHazardCategoryAvoided(categoryKey)) {
        basePenalty *= 1.4;
      }

      double categorySumPenalty = 0.0;
      int activeCount = 0;

      for (final report in reports) {
        final distToRoute = HazardAnalysisService.getMinimumDistanceToRoute(
          LatLng(report.latitude, report.longitude),
          route.polylinePoints,
        );

        // Only process reports within 200 meters of the route
        if (distToRoute <= 200.0) {
          activeCount++;
          final effectivePenalty = HazardAnalysisService.calculateEffectivePenalty(
            basePenalty: basePenalty,
            confidence: report.confidence,
            createdAt: report.createdAt,
            distanceMeters: distToRoute,
          );

          categorySumPenalty += effectivePenalty;

          // Track sub-penalty contributions
          final rWeight = SafetyConfig.getRecencyWeight(report.createdAt);
          final pWeight = SafetyConfig.getProximityWeight(distToRoute);
          totalRecencySubPenalty += (1.0 - rWeight) * basePenalty;
          totalProximitySubPenalty += (1.0 - pWeight) * basePenalty;

          detectedSignals.add(
            SafetySignal(
              hazardType: report.hazardType,
              label: report.displayLabel,
              penalty: effectivePenalty,
              description: report.description ?? 'Reported hazard near route',
              distanceMeters: distToRoute,
              createdAt: report.createdAt,
              confidence: report.confidence,
            ),
          );
        }
      }

      // Cap category cluster penalty
      final cappedCategoryPenalty = categorySumPenalty.clamp(
        0.0,
        SafetyConfig.maxCategoryPenalty,
      );
      if (categorySumPenalty > SafetyConfig.maxCategoryPenalty) {
        totalDensitySubPenalty += (categorySumPenalty - SafetyConfig.maxCategoryPenalty);
      }

      totalHazardPenalty += cappedCategoryPenalty;

      if (activeCount > 0) {
        final label = reports.first.displayLabel;
        if (preferences != null && preferences.isHazardCategoryAvoided(categoryKey)) {
          whyBullets.add('$activeCount $label reports (Avoided in your safety preferences)');
        } else if (activeCount == 1) {
          whyBullets.add('1 $label report nearby');
        } else {
          whyBullets.add('$activeCount $label reports along area');
        }
      }
    });

    // Apply route preference mode weight multipliers
    if (preferences != null) {
      if (preferences.routePreferenceMode == 'safety_priority') {
        totalHazardPenalty *= 1.15;
      } else if (preferences.routePreferenceMode == 'time_priority') {
        totalHazardPenalty *= 0.85;
      }
    }

    // Distance penalty: if this route is > 10% longer than shortest option
    double distancePenalty = 0.0;
    if (minRouteDistanceMeters > 0 &&
        route.distanceMeters > minRouteDistanceMeters * (1.0 + SafetyConfig.distanceToleranceRatio)) {
      final excessRatio = (route.distanceMeters - minRouteDistanceMeters) / minRouteDistanceMeters;
      double distWeight = 15.0;
      if (preferences != null && preferences.routePreferenceMode == 'time_priority') {
        distWeight = 25.0;
      } else if (preferences != null && preferences.routePreferenceMode == 'safety_priority') {
        distWeight = 8.0;
      }

      distancePenalty = (excessRatio * distWeight).clamp(0.0, SafetyConfig.maxDistancePenalty);
      whyBullets.add('${(excessRatio * 100).round()}% longer walking distance');
    }

    // Default positive bullet points if few hazards detected
    if (detectedSignals.isEmpty) {
      whyBullets.add('No active community hazard reports along route');
      whyBullets.add('Clear pedestrian path detected');
    } else if (whyBullets.length < 3) {
      whyBullets.add('Low hazard density along path');
    }

    final double totalPenalties = totalHazardPenalty + distancePenalty;
    final int finalScore = (100 - totalPenalties.round()).clamp(0, 100);

    return SafetyScore(
      overallScore: finalScore,
      hazardPenalty: totalHazardPenalty,
      recencyPenalty: totalRecencySubPenalty,
      proximityPenalty: totalProximitySubPenalty,
      densityPenalty: totalDensitySubPenalty,
      distancePenalty: distancePenalty,
      confidence: 0.90,
      signals: detectedSignals,
      whyBulletPoints: whyBullets,
    );
  }
}
