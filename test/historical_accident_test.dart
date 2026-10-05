import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:saferoute_ai/config/safety_config.dart';
import 'package:saferoute_ai/models/historical_accident_location.dart';
import 'package:saferoute_ai/models/route_model.dart';
import 'package:saferoute_ai/services/historical_accident_service.dart';
import 'package:saferoute_ai/services/safety_engine.dart';

void main() {
  group('Historical Accident Integration Tests', () {
    final route = RouteModel(
      polylinePoints: [
        const LatLng(21.1458, 79.0882),
        const LatLng(21.1500, 79.0900),
      ],
      distanceMeters: 1000,
      durationSeconds: 720,
    );

    test('1. CSV Parsing: Parses raw CSV content into structured internal dataset', () {
      final locations = HistoricalAccidentService.parseCsv(HistoricalAccidentService.rawCsvData);
      expect(locations.length, equals(21));
      expect(locations.first.name, contains('Old Pardi Naka Square'));
    });

    test('2. Raw dataset status: Raw CSV rows are currently unverified and excluded from scoring', () {
      final locations = HistoricalAccidentService.parseCsv(HistoricalAccidentService.rawCsvData);
      final eligible = locations.where((loc) => loc.isEligibleForScoring).toList();
      expect(eligible, isEmpty);

      final penalty = HistoricalAccidentService.calculateHistoricalPenalty(
        route: route,
        locations: locations,
      );
      expect(penalty, equals(0.0));
    });

    test('3. Near verified location: Route passing near verified location receives penalty', () {
      final verifiedLocation = HistoricalAccidentLocation(
        id: 'v1',
        name: 'Verified Spot',
        latitude: 21.1458, // Exactly on route
        longitude: 79.0882,
        type: 'historical_accident_prone_location',
        seriousAccidents: 10,
        source: 'Official Audit',
        sourceYear: 2024,
        verificationStatus: 'verified',
      );

      final penalty = HistoricalAccidentService.calculateHistoricalPenalty(
        route: route,
        locations: [verifiedLocation],
      );

      // Single eligible location on route with distance 0m:
      // maxValidCount = 10, normalizedCount = 1.0, proximity = 1.0, risk = 1.0 -> penalty = 15.0
      expect(penalty, equals(15.0));

      final score = SafetyEngine.calculateScore(
        route: route,
        nearbyReports: [],
        historicalLocations: [verifiedLocation],
      );

      expect(score.overallScore, equals(85));
      expect(score.historicalPenalty, equals(15.0));
      expect(score.whyBulletPoints, contains('Historical road-safety data considered'));
    });

    test('4. Far away location: Route far away receives no historical penalty', () {
      final verifiedFarLocation = HistoricalAccidentLocation(
        id: 'v_far',
        name: 'Far Spot',
        latitude: 21.2000, // ~6km away
        longitude: 79.2000,
        type: 'historical_accident_prone_location',
        seriousAccidents: 10,
        source: 'Official Audit',
        sourceYear: 2024,
        verificationStatus: 'verified',
      );

      final penalty = HistoricalAccidentService.calculateHistoricalPenalty(
        route: route,
        locations: [verifiedFarLocation],
      );

      expect(penalty, equals(0.0));

      final score = SafetyEngine.calculateScore(
        route: route,
        nearbyReports: [],
        historicalLocations: [verifiedFarLocation],
      );

      expect(score.overallScore, equals(100));
      expect(score.historicalPenalty, equals(0.0));
      expect(score.whyBulletPoints, isNot(contains('Historical road-safety data considered')));
    });

    test('5. Missing coordinates ignored: Rows without coordinates produce no penalty', () {
      final locNoCoords = HistoricalAccidentLocation(
        id: 'no_coords',
        name: 'No Coords Spot',
        latitude: null,
        longitude: null,
        type: 'historical_accident_prone_location',
        seriousAccidents: 8,
        source: 'Official Audit',
        sourceYear: 2024,
        verificationStatus: 'verified',
      );

      expect(locNoCoords.isEligibleForScoring, isFalse);

      final penalty = HistoricalAccidentService.calculateHistoricalPenalty(
        route: route,
        locations: [locNoCoords],
      );

      expect(penalty, equals(0.0));
    });

    test('6. Missing accident counts ignored: Rows without accident count produce no penalty', () {
      final locNoCount = HistoricalAccidentLocation(
        id: 'no_count',
        name: 'No Count Spot',
        latitude: 21.1458,
        longitude: 79.0882,
        type: 'historical_accident_prone_location',
        seriousAccidents: null,
        source: 'Official Audit',
        sourceYear: 2024,
        verificationStatus: 'verified',
      );

      expect(locNoCount.isEligibleForScoring, isFalse);

      final penalty = HistoricalAccidentService.calculateHistoricalPenalty(
        route: route,
        locations: [locNoCount],
      );

      expect(penalty, equals(0.0));
    });

    test('7. Unverified coordinates ignored: Unverified status produces no penalty', () {
      final locUnverified = HistoricalAccidentLocation(
        id: 'unverified',
        name: 'Unverified Spot',
        latitude: 21.1458,
        longitude: 79.0882,
        type: 'historical_accident_prone_location',
        seriousAccidents: 8,
        source: 'Screenshot',
        sourceYear: null,
        verificationStatus: 'coordinates_unverified',
      );

      expect(locUnverified.isEligibleForScoring, isFalse);

      final penalty = HistoricalAccidentService.calculateHistoricalPenalty(
        route: route,
        locations: [locUnverified],
      );

      expect(penalty, equals(0.0));
    });

    test('8. Single evaluation per location: Same location near multiple polyline points counted once', () {
      // Multi-point route looping back near same location
      final loopingRoute = RouteModel(
        polylinePoints: [
          const LatLng(21.1458, 79.0882),
          const LatLng(21.1459, 79.0883),
          const LatLng(21.1460, 79.0884),
        ],
        distanceMeters: 300,
        durationSeconds: 200,
      );

      final verifiedLocation = HistoricalAccidentLocation(
        id: 'v1',
        name: 'Spot 1',
        latitude: 21.1458,
        longitude: 79.0882,
        type: 'historical_accident_prone_location',
        seriousAccidents: 5,
        verificationStatus: 'verified',
      );

      final penalty = HistoricalAccidentService.calculateHistoricalPenalty(
        route: loopingRoute,
        locations: [verifiedLocation],
      );

      // Max penalty for 1 location is 15.0, not 15 * 3
      expect(penalty, equals(15.0));
    });

    test('9. Capping multiple locations: Risk sum is capped at max penalty (15 points)', () {
      final loc1 = HistoricalAccidentLocation(
        id: 'loc1',
        name: 'Spot 1',
        latitude: 21.1458,
        longitude: 79.0882,
        type: 'historical_accident_prone_location',
        seriousAccidents: 10,
        verificationStatus: 'verified',
      );

      final loc2 = HistoricalAccidentLocation(
        id: 'loc2',
        name: 'Spot 2',
        latitude: 21.1459,
        longitude: 79.0883,
        type: 'historical_accident_prone_location',
        seriousAccidents: 10,
        verificationStatus: 'verified',
      );

      final penalty = HistoricalAccidentService.calculateHistoricalPenalty(
        route: route,
        locations: [loc1, loc2],
      );

      expect(penalty, equals(SafetyConfig.maxHistoricalPenalty)); // strictly capped at 15.0
    });

    test('10. Score bounds 0-100: Final safety score strictly clamped between 0 and 100', () {
      final loc = HistoricalAccidentLocation(
        id: 'loc1',
        name: 'Spot 1',
        latitude: 21.1458,
        longitude: 79.0882,
        type: 'historical_accident_prone_location',
        seriousAccidents: 10,
        verificationStatus: 'verified',
      );

      final score = SafetyEngine.calculateScore(
        route: route,
        nearbyReports: [],
        historicalLocations: [loc],
      );

      expect(score.overallScore, equals(85));
      expect(score.overallScore, greaterThanOrEqualTo(0));
      expect(score.overallScore, lessThanOrEqualTo(100));
    });

    test('11. Backward compatibility: Existing scoring unchanged when no historical data passed', () {
      final scoreWithNull = SafetyEngine.calculateScore(
        route: route,
        nearbyReports: [],
      );

      final scoreWithEmpty = SafetyEngine.calculateScore(
        route: route,
        nearbyReports: [],
        historicalLocations: [],
      );

      expect(scoreWithNull.overallScore, equals(100));
      expect(scoreWithEmpty.overallScore, equals(100));
      expect(scoreWithNull.historicalPenalty, equals(0.0));
      expect(scoreWithEmpty.historicalPenalty, equals(0.0));
    });
  });
}
