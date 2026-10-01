import 'package:latlong2/latlong.dart';

class AppConstants {
  // App Branding
  static const String appName = 'SafeRoute AI';
  static const String appTagline = 'Smart Walking Navigation';
  static const String splashTagline = 'Walk smarter. Stay aware.';

  // Default Map Coordinates (Nagpur, Maharashtra, India)
  static const double initialLatitude = 21.1458;
  static const double initialLongitude = 79.0882;
  static const LatLng defaultLocation = LatLng(initialLatitude, initialLongitude);
  static const double defaultZoom = 14.5;
  static const double detailZoom = 16.5;

  // OpenStreetMap Tile Server
  static const String mapTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String mapPackageName = 'com.saferoute.ai';

  // API Endpoints
  static const String nominatimSearchUrl = 'https://nominatim.openstreetmap.org/search';
  static const String osrmRouteUrl = 'https://router.project-osrm.org/route/v1/foot';

  // Popular Nagpur Landmarks (Default Quick Search Options)
  static const List<Map<String, dynamic>> popularLandmarks = [
    {
      'name': 'Nagpur Railway Station',
      'address': 'Station Road, Sitabuldi, Nagpur',
      'lat': 21.1524,
      'lon': 79.0888,
    },
    {
      'name': 'VNIT Nagpur',
      'address': 'South Ambazari Road, Nagpur',
      'lat': 21.1255,
      'lon': 79.0504,
    },
    {
      'name': 'Futala Lake',
      'address': 'Futala Road, Amravati Road, Nagpur',
      'lat': 21.1542,
      'lon': 79.0435,
    },
    {
      'name': 'Sitabuldi Fort',
      'address': 'Sitabuldi, Nagpur, Maharashtra',
      'lat': 21.1464,
      'lon': 79.0841,
    },
    {
      'name': 'S.B. Jain Institute of Technology',
      'address': 'Near Kalmeshwar Road, Nagpur',
      'lat': 21.2291,
      'lon': 78.9667,
    },
  ];
}
