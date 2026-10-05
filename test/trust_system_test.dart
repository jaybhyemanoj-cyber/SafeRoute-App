import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:saferoute_ai/config/safety_config.dart';
import 'package:saferoute_ai/models/hazard_report.dart';
import 'package:saferoute_ai/models/route_model.dart';
import 'package:saferoute_ai/models/safety_score.dart';
import 'package:saferoute_ai/services/hazard_analysis_service.dart';

import 'package:saferoute_ai/services/safety_engine.dart';

void main() {
  group('Phase 4 Automated Trust System Tests', () {
    final cleanRoute = RouteModel(
      polylinePoints: [
        const LatLng(21.1458, 79.0882),
        const LatLng(21.1500, 79.0900),
      ],
      distanceMeters: 1000,
      durationSeconds: 720,
    );

    test('1. Automatic Report Expiry: Configurable durations per hazard category', () {
      final now = DateTime.now();

      // Stray animals expires in 24 hours
      final oldStrayAnimal = HazardReport(
        id: 'r_stray',
        latitude: 21.1458,
        longitude: 79.0882,
        hazardType: 'stray_animals',
        createdAt: now.subtract(const Duration(hours: 30)),
      );

      // Poor lighting expires in 7 days
      final recentLighting = HazardReport(
        id: 'r_light',
        latitude: 21.1458,
        longitude: 79.0882,
        hazardType: 'poor_lighting',
        createdAt: now.subtract(const Duration(hours: 30)),
      );

      expect(oldStrayAnimal.isExpired, isTrue);
      expect(recentLighting.isExpired, isFalse);
    });

    test('2. Expired Report Exclusion: Expired reports produce 0 penalty and do NOT affect scoring', () {
      final now = DateTime.now();
      final expiredReport = HazardReport(
        id: 'r_expired',
        latitude: 21.1458,
        longitude: 79.0882,
        hazardType: 'stray_animals',
        createdAt: now.subtract(const Duration(days: 3)), // 3 days old > 24h
      );

      final score = SafetyEngine.calculateScore(
        route: cleanRoute,
        nearbyReports: [expiredReport],
      );

      expect(score.overallScore, equals(100));
      expect(score.hazardPenalty, equals(0.0));
      expect(score.signals, isEmpty);
    });

    test('3. Verification Labels: "Community-confirmed" vs "Unconfirmed"', () {
      final unconfirmedReport = HazardReport(
        id: 'u1',
        latitude: 21.1458,
        longitude: 79.0882,
        hazardType: 'unsafe_crossing',
        createdAt: DateTime.now(),
        confirmationsCount: 1,
      );

      final confirmedReport = HazardReport(
        id: 'c1',
        latitude: 21.1458,
        longitude: 79.0882,
        hazardType: 'unsafe_crossing',
        createdAt: DateTime.now(),
        confirmationsCount: 2, // Meets threshold of 2 distinct user confirmations
      );

      expect(unconfirmedReport.isCommunityConfirmed, isFalse);
      expect(unconfirmedReport.verificationLabel, equals('Unconfirmed'));

      expect(confirmedReport.isCommunityConfirmed, isTrue);
      expect(confirmedReport.verificationLabel, equals('Community-confirmed'));
    });

    test('4. Unconfirmed Reports Influence Scoring: 2-3 confirmations NOT required to score', () {
      final unconfirmedReport = HazardReport(
        id: 'u1',
        latitude: 21.1458,
        longitude: 79.0882,
        hazardType: 'unsafe_crossing', // Base penalty 12
        createdAt: DateTime.now(),
        confidence: 1.0,
        confirmationsCount: 0, // Unconfirmed
      );

      final score = SafetyEngine.calculateScore(
        route: cleanRoute,
        nearbyReports: [unconfirmedReport],
      );

      // Unconfirmed report STILL influences scoring
      expect(score.overallScore, equals(88)); // 100 - 12
      expect(score.hazardPenalty, equals(12.0));
    });

    test('5. Community-Confirmed Boost: Confirmed report produces higher effective penalty', () {
      final now = DateTime.now();
      final unconfirmedReport = HazardReport(
        id: 'u1',
        latitude: 21.1458,
        longitude: 79.0882,
        hazardType: 'broken_footpath', // Base 8
        createdAt: now,
        confidence: 0.6,
        confirmationsCount: 1,
      );

      final confirmedReport = HazardReport(
        id: 'c1',
        latitude: 21.1458,
        longitude: 79.0882,
        hazardType: 'broken_footpath', // Base 8
        createdAt: now,
        confidence: 0.6,
        confirmationsCount: 3, // Community-confirmed
      );

      final unconfirmedPenalty = HazardAnalysisService.calculateEffectivePenalty(
        basePenalty: 8.0,
        confidence: 0.6,
        createdAt: now,
        distanceMeters: 0,
        report: unconfirmedReport,
      );

      final confirmedPenalty = HazardAnalysisService.calculateEffectivePenalty(
        basePenalty: 8.0,
        confidence: 0.6,
        createdAt: now,
        distanceMeters: 0,
        report: confirmedReport,
      );

      expect(confirmedPenalty, greaterThan(unconfirmedPenalty));
    });

    test('6. Clear Votes Influence Reduction: "No longer present" votes reduce penalty', () {
      final now = DateTime.now();
      final normalReport = HazardReport(
        id: 'n1',
        latitude: 21.1458,
        longitude: 79.0882,
        hazardType: 'road_damage',
        createdAt: now,
        confidence: 1.0,
        clearVotesCount: 0,
      );

      final clearedReport = HazardReport(
        id: 'cl1',
        latitude: 21.1458,
        longitude: 79.0882,
        hazardType: 'road_damage',
        createdAt: now,
        confidence: 1.0,
        clearVotesCount: 2, // Marked as cleared by 2 users
      );

      final normalPenalty = HazardAnalysisService.calculateEffectivePenalty(
        basePenalty: 7.0,
        confidence: 1.0,
        createdAt: now,
        distanceMeters: 0,
        report: normalReport,
      );

      final clearedPenalty = HazardAnalysisService.calculateEffectivePenalty(
        basePenalty: 7.0,
        confidence: 1.0,
        createdAt: now,
        distanceMeters: 0,
        report: clearedReport,
      );

      expect(clearedPenalty, lessThan(normalPenalty));
    });

    test('7. Duplicate Report Scaling: Cluster size scales down redundant report influence', () {
      final now = DateTime.now();

      final singlePenalty = HazardAnalysisService.calculateEffectivePenalty(
        basePenalty: 10.0,
        confidence: 1.0,
        createdAt: now,
        distanceMeters: 0,
        clusterSize: 1,
      );

      final duplicatePenalty = HazardAnalysisService.calculateEffectivePenalty(
        basePenalty: 10.0,
        confidence: 1.0,
        createdAt: now,
        distanceMeters: 0,
        clusterSize: 5, // 5 duplicate reports
      );

      expect(duplicatePenalty, lessThan(singlePenalty));
    });

    test('8. Mandatory Disclaimer Constant Text Match', () {
      const expectedDisclaimer =
          'Safety information is based on available map data and community reports. Route safety is not guaranteed. Conditions may change; stay alert and use your own judgment.';

      expect(SafetyConfig.trustSystemDisclaimer, equals(expectedDisclaimer));
      expect(SafetyScore.disclaimer, equals(expectedDisclaimer));
    });
  });
}
