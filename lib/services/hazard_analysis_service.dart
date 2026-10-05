import 'package:latlong2/latlong.dart';
import '../config/safety_config.dart';
import '../models/hazard_report.dart';

/// Recency weight configuration helper.
class HazardRecencyConfig {
  static double getWeight(DateTime createdAt) {
    return SafetyConfig.getRecencyWeight(createdAt);
  }
}

/// Service providing geographic hazard proximity, recency decay, and cluster analysis.
class HazardAnalysisService {
  static const Distance _distanceCalculator = Distance();

  /// Calculate minimum distance in meters between a LatLng point and a polyline route.
  static double getMinimumDistanceToRoute(LatLng point, List<LatLng> polyline) {
    if (polyline.isEmpty) return double.infinity;
    double minDistance = double.infinity;

    for (int i = 0; i < polyline.length; i++) {
      final dist = _distanceCalculator.as(LengthUnit.Meter, point, polyline[i]);
      if (dist < minDistance) {
        minDistance = dist;
      }
    }

    return minDistance;
  }

  /// Get proximity weight based on distance in meters.
  static double getProximityWeight(double distanceMeters) {
    return SafetyConfig.getProximityWeight(distanceMeters);
  }

  /// Calculate effective penalty for a hazard report given its distance to route.
  /// Automated Trust System Rules:
  /// - Expired reports produce 0.0 penalty.
  /// - Community-confirmed reports receive a confidence boost.
  /// - Clear/resolved votes reduce report influence.
  /// - Unconfirmed reports still influence scoring with calibrated weight.
  /// - Duplicate report clusters scale down redundant influence.
  static double calculateEffectivePenalty({
    required double basePenalty,
    required double confidence,
    required DateTime createdAt,
    required double distanceMeters,
    HazardReport? report,
    int clusterSize = 1,
  }) {
    if (report != null && report.isExpired) {
      return 0.0;
    }

    double effectiveConfidence = confidence;

    if (report != null) {
      if (report.isCommunityConfirmed) {
        effectiveConfidence = (effectiveConfidence * 1.25).clamp(0.0, 1.0);
      }
      if (report.clearVotesCount > 0) {
        final double clearFactor = (1.0 - (report.clearVotesCount * 0.35)).clamp(0.1, 1.0);
        effectiveConfidence *= clearFactor;
      }
    }

    final recencyWeight = SafetyConfig.getRecencyWeight(createdAt);
    final proximityWeight = SafetyConfig.getProximityWeight(distanceMeters);
    final double duplicateScale = 1.0 / (1.0 + 0.3 * (clusterSize - 1));

    return basePenalty * effectiveConfidence * recencyWeight * proximityWeight * duplicateScale;
  }

  /// Group nearby reports by hazard category to prevent duplicate infinite penalties.
  static Map<String, List<HazardReport>> clusterReportsByCategory(List<HazardReport> reports) {
    final Map<String, List<HazardReport>> clusters = {};
    for (final report in reports) {
      clusters.putIfAbsent(report.hazardType, () => []).add(report);
    }
    return clusters;
  }
}
