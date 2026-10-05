import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:saferoute_ai/config/safety_config.dart';
import 'package:saferoute_ai/models/hazard_report.dart';
import 'package:saferoute_ai/models/osm_feature.dart';
import 'package:saferoute_ai/models/route_model.dart';
import 'package:saferoute_ai/services/osm_infrastructure_service.dart';
import 'package:saferoute_ai/services/safety_engine.dart';

void main() {
  group('OpenStreetMap export.geojson Infrastructure Integration Tests', () {
    final cleanRoute = RouteModel(
      polylinePoints: [
        const LatLng(21.1458, 79.0882),
        const LatLng(21.1500, 79.0900),
      ],
      distanceMeters: 1000,
      durationSeconds: 720,
    );

    test('1. GeoJSON Dataset Parsing & Category Counts: Matches actual export.geojson', () {
      final file = File('assets/data/export.geojson');
      expect(file.existsSync(), isTrue);
      final jsonString = file.readAsStringSync();


      final features = OsmInfrastructureService.parseGeoJson(jsonString);
      expect(features.length, equals(1595));

      final pedestrianPaths = features.where((f) => f.category == OsmFeatureCategory.pedestrianPath).length;
      final livingStreets = features.where((f) => f.category == OsmFeatureCategory.livingStreet).length;
      final policeStations = features.where((f) => f.category == OsmFeatureCategory.policeStation).length;
      final medicalFacilities = features.where((f) => f.category == OsmFeatureCategory.medicalFacility).length;
      final commercialShops = features.where((f) => f.category == OsmFeatureCategory.commercialShop).length;

      expect(pedestrianPaths, equals(330));
      expect(livingStreets, equals(218));
      expect(policeStations, equals(26));
      expect(medicalFacilities, equals(536));
      expect(commercialShops, equals(485));
      expect(pedestrianPaths + livingStreets + policeStations + medicalFacilities + commercialShops, equals(1595));
    });

    test('2. Invalid Coordinates: Out-of-bounds or malformed coordinates are safely ignored', () {
      final invalidGeoJson = '''{
        "type": "FeatureCollection",
        "features": [
          {
            "type": "Feature",
            "geometry": { "type": "Point", "coordinates": [200.0, 300.0] },
            "properties": { "highway": "footway" }
          },
          {
            "type": "Feature",
            "geometry": { "type": "Point", "coordinates": [79.0882, 21.1458] },
            "properties": { "highway": "footway" }
          }
        ]
      }''';

      final features = OsmInfrastructureService.parseGeoJson(invalidGeoJson);
      expect(features.length, equals(1));
      expect(features.first.latitude, equals(21.1458));
    });

    test('3. Distinguish Pedestrian Paths from Living Streets', () {
      const pathFeature = OsmFeature(
        id: '1',
        latitude: 21.1458,
        longitude: 79.0882,
        category: OsmFeatureCategory.pedestrianPath,
      );

      const streetFeature = OsmFeature(
        id: '2',
        latitude: 21.1458,
        longitude: 79.0882,
        category: OsmFeatureCategory.livingStreet,
      );

      expect(pathFeature.isPedestrianPath, isTrue);
      expect(pathFeature.isLivingStreet, isFalse);
      expect(streetFeature.isPedestrianPath, isFalse);
      expect(streetFeature.isLivingStreet, isTrue);
    });

    test('4. Route Proximity & Positive Infrastructure Signal', () {
      const nearPath = OsmFeature(
        id: 'p1',
        latitude: 21.1458, // Exactly on route start
        longitude: 79.0882,
        category: OsmFeatureCategory.pedestrianPath,
      );

      const farPath = OsmFeature(
        id: 'p2',
        latitude: 21.2500, // ~12km away
        longitude: 79.2500,
        category: OsmFeatureCategory.pedestrianPath,
      );

      final adjustmentsNear = OsmInfrastructureService.calculateOsmScoreAdjustments(
        route: cleanRoute,
        features: [nearPath, farPath],
      );

      expect(adjustmentsNear.pedestrianPathCount, equals(1));
      expect(adjustmentsNear.pedestrianBonus, equals(1.0));

      final score = SafetyEngine.calculateScore(
        route: cleanRoute,
        nearbyReports: [],
        osmFeatures: [nearPath],
      );

      expect(score.overallScore, equals(100)); // 100 clamped max
      expect(score.osmInfrastructureBonus, equals(1.0));
      expect(score.whyBulletPoints, contains('Pedestrian infrastructure present'));
    });

    test('5. Missing Data Neutrality: Missing footpaths mean unknown (0 bonus, NO penalty)', () {
      // Score route with NO OSM features
      final scoreNoFeatures = SafetyEngine.calculateScore(
        route: cleanRoute,
        nearbyReports: [],
        osmFeatures: [],
      );

      expect(scoreNoFeatures.overallScore, equals(100));
      expect(scoreNoFeatures.osmInfrastructureBonus, equals(0.0));
      expect(scoreNoFeatures.osmContextualBonus, equals(0.0));
    });

    test('6. Contextual Signals Non-Guarantee: Police station adds bonus but does NOT override hazards', () {
      const policeFeat = OsmFeature(
        id: 'pol1',
        latitude: 21.1458,
        longitude: 79.0882,
        category: OsmFeatureCategory.policeStation,
      );

      final severeReport = HazardReport(
        id: 'h1',
        latitude: 21.1458,
        longitude: 79.0882,
        hazardType: 'unsafe_crossing', // 12 base penalty
        createdAt: DateTime.now(),
        confidence: 1.0,
      );

      final score = SafetyEngine.calculateScore(
        route: cleanRoute,
        nearbyReports: [severeReport],
        osmFeatures: [policeFeat],
      );

      // Hazard penalty = 12, Police bonus = 2.0 -> Score = 100 - 12 + 2 = 90
      expect(score.hazardPenalty, equals(12.0));
      expect(score.osmContextualBonus, equals(2.0));
      expect(score.overallScore, equals(90)); // Police presence does NOT guarantee 100 score
      expect(score.whyBulletPoints, contains('Contextual safety facilities nearby'));
    });

    test('7. Bonus Caps: Positive bonuses are strictly capped by SafetyConfig limits', () {
      final manyPaths = List.generate(
        20,
        (i) => OsmFeature(
          id: 'path_$i',
          latitude: 21.1458,
          longitude: 79.0882,
          category: OsmFeatureCategory.pedestrianPath,
        ),
      );

      final adjustments = OsmInfrastructureService.calculateOsmScoreAdjustments(
        route: cleanRoute,
        features: manyPaths,
      );

      expect(adjustments.totalInfrastructureBonus, equals(SafetyConfig.maxOsmPedestrianBonus)); // Capped at 5.0
    });

    test('8. Score Bounds & Backward Compatibility: Final score stays within 0-100', () {
      final scoreNull = SafetyEngine.calculateScore(
        route: cleanRoute,
        nearbyReports: [],
      );

      expect(scoreNull.overallScore, equals(100));
      expect(scoreNull.osmInfrastructureBonus, equals(0.0));
      expect(scoreNull.osmContextualBonus, equals(0.0));
    });
  });
}
