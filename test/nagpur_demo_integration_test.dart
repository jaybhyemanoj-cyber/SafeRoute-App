import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:saferoute_ai/models/route_model.dart';
import 'package:saferoute_ai/services/demo_data_service.dart';
import 'package:saferoute_ai/services/safety_engine.dart';

void main() {
  group('Nagpur Reports Integration Tests', () {
    test('1. Verify Nagpur dataset contains 15 hazard records', () {
      final reports = DemoDataService.nagpurDemoReports;
      expect(reports.length, equals(15));
    });

    test('2. Verify displayDescription strips synthetic tag prefixes cleanly', () {
      final reports = DemoDataService.nagpurDemoReports;
      for (final report in reports) {
        final cleanDesc = report.displayDescription;
        expect(cleanDesc, isNot(contains('[DEMO DATA')));
        expect(cleanDesc.isNotEmpty, isTrue);
      }
    });

    test('3. Verify all hazard types map correctly and are recognized', () {
      final reports = DemoDataService.nagpurDemoReports;
      final expectedTypes = {
        'broken_footpath',
        'heavy_traffic',
        'poor_lighting',
        'construction',
        'unsafe_crossing',
        'road_damage',
        'waterlogging',
        'stray_animals',
        'other',
      };

      final datasetTypes = reports.map((r) => r.hazardType).toSet();
      expect(datasetTypes.difference(expectedTypes), isEmpty);
    });

    test('4. Safety engine evaluates walking routes using imported hazard reports', () {
      final reports = DemoDataService.nagpurDemoReports;

      // Sitabuldi test walking route near (21.14841, 79.08405)
      final sitabuldiRoute = RouteModel(
        polylinePoints: [
          const LatLng(21.14841, 79.08405),
          const LatLng(21.1443, 79.08034),
        ],
        distanceMeters: 600,
        durationSeconds: 450,
      );

      final scoreWithHazards = SafetyEngine.calculateScore(
        route: sitabuldiRoute,
        nearbyReports: reports,
      );

      final cleanRouteScore = SafetyEngine.calculateScore(
        route: sitabuldiRoute,
        nearbyReports: const [],
      );

      expect(scoreWithHazards.overallScore, lessThan(cleanRouteScore.overallScore));
      expect(scoreWithHazards.hazardPenalty, greaterThan(0));
    });
  });
}
