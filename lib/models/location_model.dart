import 'package:latlong2/latlong.dart';

class LocationModel {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? heading;
  final DateTime timestamp;

  LocationModel({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.heading,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  LatLng toLatLng() => LatLng(latitude, longitude);

  @override
  String toString() => 'LocationModel($latitude, $longitude)';
}
