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
  /// Effective Penalty = Base Penalty * Confidence * RecencyWeight * ProximityWeight
  static double calculateEffectivePenalty({
    required double basePenalty,
    required double confidence,
    required DateTime createdAt,
    required double distanceMeters,
  }) {
    final recencyWeight = SafetyConfig.getRecencyWeight(createdAt);
    final proximityWeight = SafetyConfig.getProximityWeight(distanceMeters);

    return basePenalty * confidence * recencyWeight * proximityWeight;
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
