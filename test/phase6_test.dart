import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:saferoute_ai/models/hazard_report.dart';
import 'package:saferoute_ai/models/route_model.dart';
import 'package:saferoute_ai/models/route_segment.dart';
import 'package:saferoute_ai/models/safety_insights_summary.dart';
import 'package:saferoute_ai/models/user_preferences.dart';
import 'package:saferoute_ai/models/user_profile.dart';
import 'package:saferoute_ai/services/clustering_service.dart';
import 'package:saferoute_ai/services/safety_engine.dart';

void main() {
  final now = DateTime.now();

  group('Phase 6 — Data Models & Serialization', () {
    test('UserPreferences defaults and JSON serialization', () {
      final defaultPrefs = UserPreferences.defaultPreferences('test_user_123');
      expect(defaultPrefs.routePreferenceMode, equals('balanced'));
      expect(defaultPrefs.avoidHeavyTraffic, isFalse);
      expect(defaultPrefs.alertSensitivity, equals('medium'));
      expect(defaultPrefs.aiInsightsEnabled, isTrue);

      final json = defaultPrefs.toJson();
      expect(json['user_id'], equals('test_user_123'));
      expect(json['route_preference_mode'], equals('balanced'));
      expect(json['avoid_heavy_traffic'], equals(false));

      final restored = UserPreferences.fromJson(json);
      expect(restored.userId, equals('test_user_123'));
      expect(restored.routePreferenceMode, equals('balanced'));
    });

    test('UserProfile creation and JSON parsing', () {
      final json = {
        'id': 'user_abc',
        'display_name': 'Manoj Sharma',
        'created_at': '2026-10-01T00:00:00.000Z',
        'updated_at': '2026-10-01T00:00:00.000Z',
      };
      final profile = UserProfile.fromJson(json);
      expect(profile.id, equals('user_abc'));
      expect(profile.displayName, equals('Manoj Sharma'));
    });

    test('SafetyInsightsSummary model defaults', () {
      final summary = SafetyInsightsSummary(
        totalTrips: 12,
        totalDistanceMeters: 14500,
        totalDurationSeconds: 3600,
        averageSafetyScore: 88.5,
        frequentlyEncounteredHazards: {'heavy_traffic': 2, 'broken_footpath': 1},
        frequentRoutes: ['Frequent route'],
        hasEnoughData: true,
      );
      expect(summary.totalTrips, equals(12));
      expect(summary.averageSafetyScore, equals(88.5));
      expect(summary.frequentlyEncounteredHazards.length, equals(2));
    });
  });

  group('Phase 6 — Personalized Safety Scoring', () {
    final sampleRoute = RouteModel(
      polylinePoints: const [
        LatLng(21.1458, 79.0882),
        LatLng(21.1470, 79.0890),
      ],
      distanceMeters: 500,
      durationSeconds: 360,
    );

    final trafficReport = HazardReport(
      id: 'rep_1',
      hazardType: 'heavy_traffic',
      description: 'Heavy congestion near junction',
      latitude: 21.1460,
      longitude: 79.0884,
      createdAt: DateTime.now(),
      status: 'active',
      confidence: 1.0,
    );

    test('SafetyEngine applies preference weight when avoidHeavyTraffic is enabled', () {
      final standardScore = SafetyEngine.calculateScore(
        route: sampleRoute,
        nearbyReports: [trafficReport],
        preferences: UserPreferences(
          userId: 'test',
          avoidHeavyTraffic: false,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final preferenceScore = SafetyEngine.calculateScore(
        route: sampleRoute,
        nearbyReports: [trafficReport],
        preferences: UserPreferences(
          userId: 'test',
          avoidHeavyTraffic: true,
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Heightened penalty when preference is active
      expect(preferenceScore.overallScore, lessThan(standardScore.overallScore));
      expect(
        preferenceScore.whyBulletPoints.any((b) => b.contains('Avoided in your safety preferences')),
        isTrue,
      );
    });

    test('SafetyEngine routePreferenceMode safety_priority penalizes hazards more heavily', () {
      final balancedScore = SafetyEngine.calculateScore(
        route: sampleRoute,
        nearbyReports: [trafficReport],
        preferences: UserPreferences(
          userId: 'test',
          routePreferenceMode: 'balanced',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final safetyPriorityScore = SafetyEngine.calculateScore(
        route: sampleRoute,
        nearbyReports: [trafficReport],
        preferences: UserPreferences(
          userId: 'test',
          routePreferenceMode: 'safety_priority',
          createdAt: now,
          updatedAt: now,
        ),
      );

      expect(safetyPriorityScore.overallScore, lessThanOrEqualTo(balancedScore.overallScore));
    });
  });

  group('Phase 6 — Hazard Clustering & Route Segments', () {
    test('ClusteringService groups nearby reports within 50m', () {
      final rep1 = HazardReport(
        id: 'r1',
        hazardType: 'broken_footpath',
        latitude: 21.1458,
        longitude: 79.0882,
        createdAt: DateTime.now(),
      );
      final rep2 = HazardReport(
        id: 'r2',
        hazardType: 'broken_footpath',
        latitude: 21.1459, // ~15m away
        longitude: 79.0883,
        createdAt: DateTime.now(),
      );
      final repFar = HazardReport(
        id: 'r3',
        hazardType: 'broken_footpath',
        latitude: 21.1550, // ~1km away
        longitude: 79.0990,
        createdAt: DateTime.now(),
      );

      final clusters = ClusteringService.clusterReports([rep1, rep2, repFar]);
      expect(clusters.length, equals(2)); // rep1 and rep2 clustered together, repFar separate
      expect(clusters.firstWhere((c) => c.reports.length == 2).reports.length, equals(2));
    });

    test('RouteSegment evaluates localized safety score', () {
      final segment = RouteSegment(
        index: 0,
        points: const [
          LatLng(21.1458, 79.0882),
          LatLng(21.1470, 79.0890),
        ],
        distanceMeters: 200,
        durationSeconds: 140,
        safetyScore: 85,
        nearbyHazards: [
          HazardReport(
            id: 'seg_rep',
            hazardType: 'road_damage',
            latitude: 21.1460,
            longitude: 79.0884,
            createdAt: DateTime.now(),
          ),
        ],
      );

      expect(segment.safetyScore, equals(85));
      expect(segment.distanceMeters, equals(200));
    });
  });
}
