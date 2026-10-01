import 'package:latlong2/latlong.dart';

class Destination {
  final String title;
  final String address;
  final double latitude;
  final double longitude;

  Destination({
    required this.title,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  LatLng toLatLng() => LatLng(latitude, longitude);

  factory Destination.fromNominatimJson(Map<String, dynamic> json) {
    final String displayName = json['display_name'] ?? 'Unknown Location';
    final List<String> parts = displayName.split(',');
    
    final String title = parts.isNotEmpty ? parts.first.trim() : displayName;
    final String address = parts.length > 1 
        ? parts.sublist(1, parts.length > 3 ? 3 : parts.length).join(',').trim() 
        : displayName;

    return Destination(
      title: title,
      address: address,
      latitude: double.parse(json['lat'].toString()),
      longitude: double.parse(json['lon'].toString()),
    );
  }

  @override
  String toString() => 'Destination($title, $latitude, $longitude)';
}
