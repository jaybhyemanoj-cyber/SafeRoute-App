import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:saferoute_ai/models/destination.dart';
import 'package:saferoute_ai/models/hazard_report.dart';
import 'package:saferoute_ai/models/navigation_instruction.dart';
import 'package:saferoute_ai/models/navigation_state.dart';
import 'package:saferoute_ai/models/route_candidate.dart';
import 'package:saferoute_ai/models/route_model.dart';
import 'package:saferoute_ai/services/live_navigation_service.dart';
import 'package:saferoute_ai/services/safety_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 4 Live Navigation Tests', () {
    const origin = LatLng(21.1458, 79.0882);
    final destination = Destination(
      title: 'Nagpur Station',
      address: 'Sitabuldi, Nagpur',
      latitude: 21.1524,
      longitude: 79.0888,
    );

    final route = RouteModel(
      polylinePoints: [
        origin,
        const LatLng(21.1490, 79.0885),
        destination.toLatLng(),
      ],
      distanceMeters: 800,
      durationSeconds: 600,
      instructions: const [
        NavigationInstruction(
          type: 'depart',
          modifier: 'straight',
          streetName: 'Station Road',
          distanceMeters: 400,
          durationSeconds: 300,
          location: origin,
        ),
        NavigationInstruction(
          type: 'turn',
          modifier: 'left',
          streetName: 'Main Street',
          distanceMeters: 400,
          durationSeconds: 300,
          location: LatLng(21.1490, 79.0885),
        ),
      ],
    );

    final candidate = RouteCandidate(
      id: 'cand_1',
      title: 'Route A',
      route: route,
      safetyScore: SafetyEngine.calculateScore(route: route, nearbyReports: []),
      hazardCount: 0,
      riskSignals: [],
      isRecommended: true,
    );

    test('1. LiveNavigationService initializes and starts in navigating state', () {
      final navService = LiveNavigationService();

      navService.startNavigation(
        destination: destination,
        candidate: candidate,
        initialUserLocation: origin,
        initialNearbyReports: [],
      );

      expect(navService.state, equals(NavigationState.navigating));
      expect(navService.destination?.title, equals('Nagpur Station'));
      expect(navService.remainingDistanceMeters, greaterThan(0));
      expect(navService.currentInstruction, isNotNull);
      expect(navService.currentInstruction?.streetName, equals('Station Road'));
      navService.dispose();
    });

    test('2. NavigationInstruction formats maneuver text and icons', () {
      const turnLeft = NavigationInstruction(
        type: 'turn',
        modifier: 'left',
        streetName: 'Subhash Road',
        distanceMeters: 250,
        durationSeconds: 180,
        location: LatLng(21.1, 79.1),
      );

      expect(turnLeft.formattedText, equals('Turn left onto Subhash Road'));
      expect(turnLeft.formattedDistance, equals('250 m'));
    });

    test('3. Hazard alert deduplication and dismiss', () {
      final navService = LiveNavigationService();
      final report = HazardReport(
        id: 'hazard_101',
        latitude: origin.latitude,
        longitude: origin.longitude,
        hazardType: 'poor_lighting',
        createdAt: DateTime.now(),
      );

      navService.startNavigation(
        destination: destination,
        candidate: candidate,
        initialUserLocation: origin,
        initialNearbyReports: [report],
      );

      expect(navService.activeHazardAlert, isNull);

      navService.dismissHazardAlert();
      expect(navService.activeHazardAlert, isNull);
      navService.dispose();
    });
  });
}
