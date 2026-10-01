import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/destination.dart';
import '../utils/constants.dart';

class GeocodingService {
  static final GeocodingService _instance = GeocodingService._internal();
  factory GeocodingService() => _instance;
  GeocodingService._internal();

  /// Search places via OpenStreetMap Nominatim Geocoding API
  Future<List<Destination>> searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      return getPopularLandmarks();
    }

    try {
      final uri = Uri.parse(
        '${AppConstants.nominatimSearchUrl}?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=8',
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'SafeRouteAI_App/1.0 (${AppConstants.mapPackageName})',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final results = jsonList
            .map((item) => Destination.fromNominatimJson(item as Map<String, dynamic>))
            .toList();

        if (results.isNotEmpty) {
          return results;
        }
      }
    } catch (e) {
      // Graceful fallback to search in local landmarks on error or timeout
    }

    // Filter local popular landmarks if query matches
    final localMatches = AppConstants.popularLandmarks
        .where((item) =>
            item['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
            item['address'].toString().toLowerCase().contains(query.toLowerCase()))
        .map((item) => Destination(
              title: item['name'] as String,
              address: item['address'] as String,
              latitude: item['lat'] as double,
              longitude: item['lon'] as double,
            ))
        .toList();

    return localMatches.isNotEmpty ? localMatches : getPopularLandmarks();
  }

  /// Returns popular Nagpur landmarks for initial search display
  List<Destination> getPopularLandmarks() {
    return AppConstants.popularLandmarks
        .map((item) => Destination(
              title: item['name'] as String,
              address: item['address'] as String,
              latitude: item['lat'] as double,
              longitude: item['lon'] as double,
            ))
        .toList();
  }
}
