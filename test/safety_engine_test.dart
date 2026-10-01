import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:saferoute_ai/config/safety_config.dart';
import 'package:saferoute_ai/models/hazard_report.dart';
import 'package:saferoute_ai/models/route_model.dart';
import 'package:saferoute_ai/services/explanation_service.dart';
import 'package:saferoute_ai/services/safety_engine.dart';

void main() {
  group('Phase 3 Safety Engine Tests', () {
    final cleanRoute = RouteModel(
      polylinePoints: [
        const LatLng(21.1458, 79.0882),
        const LatLng(21.1500, 79.0900),
      ],
      distanceMeters: 1000,
      durationSeconds: 720,
    );

    test('1. Hazard penalty: Verify each hazard type produces expected base penalty', () {
      final categories = [
        'poor_lighting',
        'broken_footpath',
        'road_damage',
        'construction',
        'unsafe_crossing',
        'heavy_traffic',
        'waterlogging',
        'suspicious_activity',
        'stray_animals',
        'other',
      ];

      for (final cat in categories) {
        final report = HazardReport(
          id: 'rep_$cat',
          latitude: 21.1458,
          longitude: 79.0882,
          hazardType: cat,
          createdAt: DateTime.now(),
          confidence: 1.0,
        );

        final score = SafetyEngine.calculateScore(
          route: cleanRoute,
          nearbyReports: [report],
        );

        final expectedPenalty = SafetyConfig.hazardWeights[cat] ?? 5.0;
        expect(100 - score.overallScore, equals(expectedPenalty.round()));
      }
    });

    test('2. Recency: Verify recent reports influence scores more than old reports', () {
      final now = DateTime.now();

      final recentReport = HazardReport(
        id: 'recent',
        latitude: 21.1458,
        longitude: 79.0882,
        hazardType: 'unsafe_crossing',
        createdAt: now.subtract(const Duration(hours: 2)),
        confidence: 1.0,
      );

      final oldReport = HazardReport(
        id: 'old',
        latitude: 21.1458,
        longitude: 79.0882,
        hazardType: 'unsafe_crossing',
        createdAt: now.subtract(const Duration(days: 15)),
        confidence: 1.0,
      );

      final recentScore = SafetyEngine.calculateScore(
        route: cleanRoute,
        nearbyReports: [recentReport],
      );

      final oldScore = SafetyEngine.calculateScore(
        route: cleanRoute,
        nearbyReports: [oldReport],
      );

      expect(recentScore.overallScore, lessThan(oldScore.overallScore));
    });

    test('3. Proximity: Verify nearby hazards have greater influence than distant hazards', () {
      final now = DateTime.now();

      final closeReport = HazardReport(
        id: 'close',
        latitude: 21.1458,
        longitude: 79.0882, // Exactly on route (0m)
        hazardType: 'suspicious_activity',
        createdAt: now,
        confidence: 1.0,
      );

      final farReport = HazardReport(
        id: 'far',
        latitude: 21.1470,
        longitude: 79.0895, // ~150m from route
        hazardType: 'suspicious_activity',
        createdAt: now,
        confidence: 1.0,
      );

      final closeScore = SafetyEngine.calculateScore(
        route: cleanRoute,
        nearbyReports: [closeReport],
      );

      final farScore = SafetyEngine.calculateScore(
        route: cleanRoute,
        nearbyReports: [farReport],
      );

      expect(closeScore.overallScore, lessThan(farScore.overallScore));
    });

    test('4. Confidence: Verify low-confidence reports contribute less penalty', () {
      final now = DateTime.now();

      final highConfReport = HazardReport(
        id: 'high_conf',
        latitude: 21.1458,
        longitude: 79.0882,
        hazardType: 'road_damage',
        createdAt: now,
        confidence: 1.0,
      );

      final lowConfReport = HazardReport(
        id: 'low_conf',
        latitude: 21.1458,
        longitude: 79.0882,
        hazardType: 'road_damage',
        createdAt: now,
        confidence: 0.3,
      );

      final highConfScore = SafetyEngine.calculateScore(
        route: cleanRoute,
        nearbyReports: [highConfReport],
      );

      final lowConfScore = SafetyEngine.calculateScore(
        route: cleanRoute,
        nearbyReports: [lowConfReport],
      );

      expect(highConfScore.overallScore, lessThan(lowConfScore.overallScore));
    });

    test('5. Density: Verify multiple reports increase signal but stay capped per category', () {
      final now = DateTime.now();
      final List<HazardReport> multipleReports = List.generate(
        10,
        (i) => HazardReport(
          id: 'multi_$i',
          latitude: 21.1458,
          longitude: 79.0882,
          hazardType: 'unsafe_crossing', // Base 12
          createdAt: now,
          confidence: 1.0,
        ),
      );

      final score = SafetyEngine.calculateScore(
        route: cleanRoute,
        nearbyReports: multipleReports,
      );

      // Capped category penalty max = 25
      expect(score.overallScore, equals(75));
    });

    test('6. Distance trade-off: Verify route length influences score appropriately', () {
      final longRoute = RouteModel(
        polylinePoints: [
          const LatLng(21.1458, 79.0882),
          const LatLng(21.1550, 79.0950),
        ],
        distanceMeters: 1600, // 60% longer than 1000m
        durationSeconds: 1100,
      );

      final score = SafetyEngine.calculateScore(
        route: longRoute,
        nearbyReports: [],
        minRouteDistanceMeters: 1000,
      );

      expect(score.overallScore, lessThan(100));
      expect(score.distancePenalty, greaterThan(0));
    });

    test('7. Score bounds: Verify score is strictly clamped between 0 and 100', () {
      final now = DateTime.now();
      final severeReports = [
        'poor_lighting',
        'broken_footpath',
        'road_damage',
        'construction',
        'unsafe_crossing',
        'heavy_traffic',
        'waterlogging',
        'suspicious_activity',
        'stray_animals',
        'other',
      ].map((cat) => HazardReport(
        id: 'sev_$cat',
        latitude: 21.1458,
        longitude: 79.0882,
        hazardType: cat,
        createdAt: now,
        confidence: 1.0,
      )).toList();

      final score = SafetyEngine.calculateScore(
        route: cleanRoute,
        nearbyReports: severeReports,
      );

      expect(score.overallScore, greaterThanOrEqualTo(0));
      expect(score.overallScore, lessThanOrEqualTo(100));
    });

    test('8. Empty data: Verify route with no reports produces valid score & explanation', () {
      final score = SafetyEngine.calculateScore(
        route: cleanRoute,
        nearbyReports: [],
      );

      expect(score.overallScore, equals(100));
      expect(score.whyBulletPoints, contains('No active community hazard reports along route'));
    });

    test('9. Offline / Empty network fallback: ExplanationService handles gracefully', () async {
      final score = SafetyEngine.calculateScore(
        route: cleanRoute,
        nearbyReports: [],
      );

      final bullets = await ExplanationService.getScoreExplanation(
        safetyScore: score,
        distanceMeters: 1000,
        durationSeconds: 720,
        geminiApiKey: null, // Test deterministic fallback
      );

      expect(bullets, isNotEmpty);
      expect(bullets.first, contains('No active community hazard reports'));
    });
  });
}
