import 'package:latlong2/latlong.dart';
import 'navigation_instruction.dart';

class RouteModel {
  final List<LatLng> polylinePoints;
  final double distanceMeters;
  final double durationSeconds;
  final String? summary;
  final List<NavigationInstruction> instructions;

  RouteModel({
    required this.polylinePoints,
    required this.distanceMeters,
    required this.durationSeconds,
    this.summary,
    this.instructions = const [],
  });

  /// Formatted distance string e.g. "2.4 km" or "850 m"
  String get formattedDistance {
    if (distanceMeters >= 1000) {
      final km = distanceMeters / 1000;
      return '${km.toStringAsFixed(1)} km';
    } else {
      return '${distanceMeters.round()} m';
    }
  }

  /// Formatted walking duration string e.g. "29 min" or "1 hr 15 min"
  String get formattedDuration {
    final minutes = (durationSeconds / 60).round();
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMins = minutes % 60;
      return remainingMins > 0 ? '$hours hr $remainingMins min' : '$hours hr';
    } else {
      return '$minutes min';
    }
  }
}
