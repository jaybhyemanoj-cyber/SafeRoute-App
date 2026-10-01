import 'package:latlong2/latlong.dart';
import 'hazard_report.dart';

/// Represents a distinct sub-segment of a walking route polyline (Phase 6).
class RouteSegment {
  final int index;
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final List<HazardReport> nearbyHazards;
  final int safetyScore;
  final String relevanceTag;

  const RouteSegment({
    required this.index,
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.nearbyHazards,
    required this.safetyScore,
    this.relevanceTag = 'standard',
  });
}
