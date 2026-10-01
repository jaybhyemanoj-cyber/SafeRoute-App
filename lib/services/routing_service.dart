import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/navigation_instruction.dart';
import '../models/route_model.dart';
import '../utils/constants.dart';

class RoutingService {
  static final RoutingService _instance = RoutingService._internal();
  factory RoutingService() => _instance;
  RoutingService._internal();

  /// Calculate walking route alternatives between origin and destination using OSRM.
  Future<List<RouteModel>> getWalkingRouteAlternatives({
    required double originLat,
    required double originLon,
    required double destLat,
    required double destLon,
  }) async {
    final String url =
        '${AppConstants.osrmRouteUrl}/$originLon,$originLat;$destLon,$destLat?overview=full&geometries=geojson&steps=true&alternatives=true';

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 'Ok' &&
            data['routes'] != null &&
            (data['routes'] as List).isNotEmpty) {
          final routesList = data['routes'] as List;
          final List<RouteModel> parsedRoutes = [];

          for (final route in routesList.take(3)) {
            final double distance = (route['distance'] as num).toDouble();
            final double duration = (route['duration'] as num).toDouble();

            final geometry = route['geometry'];
            final coordinates = geometry['coordinates'] as List;

            final List<LatLng> polylinePoints = coordinates.map((coord) {
              final list = coord as List;
              return LatLng(
                (list[1] as num).toDouble(),
                (list[0] as num).toDouble(),
              );
            }).toList();

            // Parse turn-by-turn steps from OSRM leg response
            final List<NavigationInstruction> instructions = [];
            final legs = route['legs'] as List?;
            if (legs != null && legs.isNotEmpty) {
              final steps = legs[0]['steps'] as List?;
              if (steps != null) {
                for (final step in steps) {
                  final m = step['maneuver'];
                  final locationList = m?['location'] as List?;
                  final latLng = (locationList != null && locationList.length >= 2)
                      ? LatLng((locationList[1] as num).toDouble(), (locationList[0] as num).toDouble())
                      : polylinePoints.first;

                  instructions.add(
                    NavigationInstruction(
                      type: m?['type']?.toString() ?? 'turn',
                      modifier: m?['modifier']?.toString(),
                      streetName: step['name']?.toString() ?? '',
                      distanceMeters: (step['distance'] as num?)?.toDouble() ?? 0.0,
                      durationSeconds: (step['duration'] as num?)?.toDouble() ?? 0.0,
                      location: latLng,
                    ),
                  );
                }
              }
            }

            parsedRoutes.add(
              RouteModel(
                polylinePoints: polylinePoints,
                distanceMeters: distance,
                durationSeconds: duration,
                summary: route['legs']?[0]?['summary'] as String?,
                instructions: instructions.isNotEmpty
                    ? instructions
                    : _synthesizeFallbackInstructions(polylinePoints, distance, duration),
              ),
            );
          }

          if (parsedRoutes.isNotEmpty) {
            return parsedRoutes;
          }
        }
      }
    } catch (e) {
      debugPrint('[RoutingService] OSRM alternatives error: $e');
    }

    // Geodesic single fallback path if network or OSRM API is unreachable
    return [_createFallbackRoute(originLat, originLon, destLat, destLon)];
  }

  /// Calculate single primary walking route (Phase 1 compatibility).
  Future<RouteModel?> getWalkingRoute({
    required double originLat,
    required double originLon,
    required double destLat,
    required double destLon,
  }) async {
    final alternatives = await getWalkingRouteAlternatives(
      originLat: originLat,
      originLon: originLon,
      destLat: destLat,
      destLon: destLon,
    );
    if (alternatives.isNotEmpty) {
      return alternatives.first;
    }

    return _createFallbackRoute(originLat, originLon, destLat, destLon);
  }

  RouteModel _createFallbackRoute(
    double originLat,
    double originLon,
    double destLat,
    double destLon,
  ) {
    const Distance distanceCalculator = Distance();
    final double distanceMeters = distanceCalculator.as(
      LengthUnit.Meter,
      LatLng(originLat, originLon),
      LatLng(destLat, destLon),
    );

    final double durationSeconds = distanceMeters / 1.25;
    final midLat = (originLat + destLat) / 2;
    final midLon = (originLon + destLon) / 2;

    final polylinePoints = [
      LatLng(originLat, originLon),
      LatLng(midLat, midLon),
      LatLng(destLat, destLon),
    ];

    return RouteModel(
      polylinePoints: polylinePoints,
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      summary: 'Direct Walking Path',
      instructions: _synthesizeFallbackInstructions(polylinePoints, distanceMeters, durationSeconds),
    );
  }

  List<NavigationInstruction> _synthesizeFallbackInstructions(
    List<LatLng> polylinePoints,
    double totalDistance,
    double totalDuration,
  ) {
    if (polylinePoints.isEmpty) return [];

    final origin = polylinePoints.first;
    final destination = polylinePoints.last;

    return [
      NavigationInstruction(
        type: 'depart',
        modifier: 'straight',
        streetName: 'Walking Path',
        distanceMeters: totalDistance * 0.9,
        durationSeconds: totalDuration * 0.9,
        location: origin,
      ),
      NavigationInstruction(
        type: 'arrive',
        modifier: 'straight',
        streetName: 'Destination',
        distanceMeters: 0,
        durationSeconds: 0,
        location: destination,
      ),
    ];
  }
}
