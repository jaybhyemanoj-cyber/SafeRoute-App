import '../models/hazard_report.dart';
import '../models/historical_accident_location.dart';
import '../models/osm_feature.dart';
import '../models/route_candidate.dart';
import '../models/route_model.dart';
import '../models/user_preferences.dart';
import 'safety_engine.dart';

/// Service analyzing and comparing multiple route alternatives.
class RouteAnalysisService {
  /// Evaluate and rank route alternatives against community hazards, historical data, and OSM infrastructure.
  static List<RouteCandidate> analyzeRouteCandidates({
    required List<RouteModel> routes,
    required List<HazardReport> nearbyReports,
    List<HistoricalAccidentLocation>? historicalLocations,
    List<OsmFeature>? osmFeatures,
    UserPreferences? preferences,
  }) {
    if (routes.isEmpty) return [];

    // Find shortest distance across candidates
    double minDistance = double.infinity;
    for (final r in routes) {
      if (r.distanceMeters < minDistance) {
        minDistance = r.distanceMeters;
      }
    }

    final List<RouteCandidate> candidates = [];
    const titles = ['Route A', 'Route B', 'Route C'];

    for (int i = 0; i < routes.length; i++) {
      final route = routes[i];
      final safetyScore = SafetyEngine.calculateScore(
        route: route,
        nearbyReports: nearbyReports,
        historicalLocations: historicalLocations,
        osmFeatures: osmFeatures,
        minRouteDistanceMeters: minDistance,
        preferences: preferences,
      );

      final title = i < titles.length ? titles[i] : 'Route ${i + 1}';

      candidates.add(
        RouteCandidate(
          id: 'candidate_$i',
          title: title,
          route: route,
          safetyScore: safetyScore,
          hazardCount: safetyScore.signals.length,
          riskSignals: safetyScore.signals,
          isRecommended: false,
        ),
      );
    }

    // Sort candidates primarily by safety score descending, then by distance ascending
    candidates.sort((a, b) {
      final scoreComp = b.safetyScore.overallScore.compareTo(a.safetyScore.overallScore);
      if (scoreComp != 0) return scoreComp;
      return a.route.distanceMeters.compareTo(b.route.distanceMeters);
    });

    // Mark top-ranked candidate as recommended
    final List<RouteCandidate> rankedCandidates = [];
    for (int i = 0; i < candidates.length; i++) {
      final cand = candidates[i];
      rankedCandidates.add(
        RouteCandidate(
          id: cand.id,
          title: cand.title,
          route: cand.route,
          safetyScore: cand.safetyScore,
          hazardCount: cand.hazardCount,
          riskSignals: cand.riskSignals,
          isRecommended: i == 0,
        ),
      );
    }

    return rankedCandidates;
  }
}
