import 'package:flutter/services.dart' show rootBundle;
import 'package:latlong2/latlong.dart';
import '../config/safety_config.dart';
import '../models/historical_accident_location.dart';
import '../models/route_model.dart';
import 'hazard_analysis_service.dart';

/// Private service for loading and processing historical accident dataset records internally.
/// Raw rows and coordinates are strictly kept internal to the scoring engine.
class HistoricalAccidentService {
  static const String _defaultCsvPath =
      'assets/data/saferoute_nagpur_historical_accident_locations.csv';

  /// Embedded fallback CSV data matching saferoute_nagpur_historical_accident_locations.csv
  static const String rawCsvData = '''id,name,latitude,longitude,type,serious_accidents,source,source_year,verification_status,notes
1,Old Pardi Naka Square (Pardi),,,historical_accident_prone_location,8,User-provided screenshot; original publication not verified,,coordinates_unverified,Historical count from user-provided screenshot. Not live/current risk data.
2,Hanuman Mandir Square (Pardi),,,historical_accident_prone_location,5,User-provided screenshot; original publication not verified,,coordinates_unverified,Historical count from user-provided screenshot. Not live/current risk data.
3,Prakash High School to Kapsi Bridge (Pardi),,,historical_accident_prone_location,15,User-provided screenshot; original publication not verified,,coordinates_unverified,Road stretch; exact geometry needs verification. Not live/current risk data.
4,Maruti Showroom Square (Indora),,,historical_accident_prone_location,12,User-provided screenshot; original publication not verified,,coordinates_unverified,Historical count from user-provided screenshot. Not live/current risk data.
5,"8th Mile Square, Amravati Road (Wadi)",,,historical_accident_prone_location,5,User-provided screenshot; original publication not verified,,coordinates_unverified,Historical count from user-provided screenshot. Not live/current risk data.
6,Uppalwadi Bridge (Indora),,,historical_accident_prone_location,2,User-provided screenshot; original publication not verified,,coordinates_unverified,Historical count from user-provided screenshot. Not live/current risk data.
7,Jaripatka Square (Indora),,,historical_accident_prone_location,4,User-provided screenshot; original publication not verified,,coordinates_unverified,Historical count from user-provided screenshot. Not live/current risk data.
8,Vita Bhatti Square (Indora),,,historical_accident_prone_location,3,User-provided screenshot; original publication not verified,,coordinates_unverified,Historical count from user-provided screenshot. Not live/current risk data.
9,Mahesh Dhaba (Beltarodi),,,historical_accident_prone_location,3,User-provided screenshot; original publication not verified,,coordinates_unverified,Historical count from user-provided screenshot. Not live/current risk data.
10,Chinchbhuwan Square (Beltarodi),,,historical_accident_prone_location,4,User-provided screenshot; original publication not verified,,coordinates_unverified,Historical count from user-provided screenshot. Not live/current risk data.
11,Manewada Square (Ajni),,,historical_accident_prone_location,2,User-provided screenshot; original publication not verified,,coordinates_unverified,Historical count from user-provided screenshot. Not live/current risk data.
12,Mhalgi Nagar Square (Sakkardara),,,historical_accident_prone_location,2,User-provided screenshot; original publication not verified,,coordinates_unverified,Historical count from user-provided screenshot. Not live/current risk data.
13,Waddhamna (Wadi),,,historical_accident_prone_location,2,User-provided screenshot; original publication not verified,,coordinates_unverified,Historical count from user-provided screenshot. Not live/current risk data.
14,Dongargaon (Hingna),,,historical_accident_prone_location,1,User-provided screenshot; original publication not verified,,coordinates_unverified,Historical count from user-provided screenshot. Not live/current risk data.
15,Rajiv Nagar (MIDC),,,historical_accident_prone_location,2,User-provided screenshot; original publication not verified,,coordinates_unverified,Historical count from user-provided screenshot. Not live/current risk data.
16,IC Square (MIDC),,,historical_accident_prone_location,,User-provided screenshot; original publication not verified,,count_and_coordinates_unverified,Accident count is not visible in the screenshot; do not infer zero. Not live/current risk data.
17,Maharajbagh Square (Sitabuldi),,,historical_accident_prone_location,1,User-provided screenshot; original publication not verified,,coordinates_unverified,Historical count from user-provided screenshot. Not live/current risk data.
18,Chhatrapati Square (Dhantoli),,,historical_accident_prone_location,3,User-provided screenshot; original publication not verified,,coordinates_unverified,Historical count from user-provided screenshot. Not live/current risk data.
19,Chamat Chakki Square (Hudkeshwar),,,historical_accident_prone_location,1,User-provided screenshot; original publication not verified,,coordinates_unverified,Historical count from user-provided screenshot. Not live/current risk data.
20,Dighori Bridge (Sakkardara),,,historical_accident_prone_location,,User-provided screenshot; original publication not verified,,count_and_coordinates_unverified,Additional area; accident count not provided. Not live/current risk data.
21,Telephone Exchange Square (Hudkeshwar),,,historical_accident_prone_location,,User-provided screenshot; original publication not verified,,count_and_coordinates_unverified,Additional area; accident count not provided. Not live/current risk data.''';

  /// Load historical accident dataset locations from Flutter asset bundle with fallback to raw CSV.
  static Future<List<HistoricalAccidentLocation>> loadLocations({String? customCsvPath}) async {
    try {
      final csvString = await rootBundle.loadString(customCsvPath ?? _defaultCsvPath);
      return parseCsv(csvString);
    } catch (_) {
      return parseCsv(rawCsvData);
    }
  }

  /// Parse CSV string into structured [HistoricalAccidentLocation] records.
  static List<HistoricalAccidentLocation> parseCsv(String csvContent) {
    final List<HistoricalAccidentLocation> locations = [];
    final lines = csvContent.split(RegExp(r'\r?\n'));
    if (lines.isEmpty) return locations;

    // First line is header
    final headerLine = lines.first;
    final headers = _parseCsvRow(headerLine).map((h) => h.toLowerCase().trim()).toList();

    final int idIdx = headers.indexOf('id');
    final int nameIdx = headers.indexOf('name');
    final int latIdx = headers.indexOf('latitude');
    final int lonIdx = headers.indexOf('longitude');
    final int typeIdx = headers.indexOf('type');
    final int countIdx = headers.indexOf('serious_accidents');
    final int sourceIdx = headers.indexOf('source');
    final int yearIdx = headers.indexOf('source_year');
    final int statusIdx = headers.indexOf('verification_status');
    final int notesIdx = headers.indexOf('notes');

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final fields = _parseCsvRow(line);

      String getField(int idx) => (idx >= 0 && idx < fields.length) ? fields[idx].trim() : '';

      final id = getField(idIdx);
      final name = getField(nameIdx);
      final rawLat = getField(latIdx);
      final rawLon = getField(lonIdx);
      final type = getField(typeIdx).isNotEmpty ? getField(typeIdx) : 'historical_accident_prone_location';
      final rawCount = getField(countIdx);
      final source = getField(sourceIdx).isNotEmpty ? getField(sourceIdx) : null;
      final rawYear = getField(yearIdx);
      final status = getField(statusIdx);
      final notes = getField(notesIdx).isNotEmpty ? getField(notesIdx) : null;

      final double? latitude = rawLat.isNotEmpty ? double.tryParse(rawLat) : null;
      final double? longitude = rawLon.isNotEmpty ? double.tryParse(rawLon) : null;
      // Missing accident count MUST remain null (unknown), not 0
      final int? seriousAccidents = rawCount.isNotEmpty ? int.tryParse(rawCount) : null;
      final int? sourceYear = rawYear.isNotEmpty ? int.tryParse(rawYear) : null;

      locations.add(
        HistoricalAccidentLocation(
          id: id.isNotEmpty ? id : '$i',
          name: name,
          latitude: latitude,
          longitude: longitude,
          type: type,
          seriousAccidents: seriousAccidents,
          source: source,
          sourceYear: sourceYear,
          verificationStatus: status,
          notes: notes,
        ),
      );
    }

    return locations;
  }

  /// Helper to parse a single CSV line while respecting quoted commas.
  static List<String> _parseCsvRow(String line) {
    final List<String> result = [];
    final StringBuffer current = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString());
        current.clear();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString());
    return result;
  }

  /// Calculate historical risk penalty for a route based on eligible historical accident locations.
  /// Formula:
  /// normalized_count = min(accident_count / max_valid_count, 1.0)
  /// proximity_factor = max(0, 1 - distance_metres / radius_metres)
  /// location_risk = normalized_count * proximity_factor
  /// historical_risk = min(1.0, sum(location_risk))
  /// historical_penalty = historical_risk * 15.0
  static double calculateHistoricalPenalty({
    required RouteModel route,
    required List<HistoricalAccidentLocation> locations,
    double radiusMeters = SafetyConfig.historicalSearchRadiusMeters,
    double maxPenalty = SafetyConfig.maxHistoricalPenalty,
  }) {
    if (route.polylinePoints.isEmpty || locations.isEmpty) {
      return 0.0;
    }

    // Filter to eligible locations only: valid non-null coordinates, valid accident count, verified status
    final eligibleLocations = locations.where((loc) => loc.isEligibleForScoring).toList();
    if (eligibleLocations.isEmpty) {
      return 0.0;
    }

    // Find highest valid count in eligible dataset
    int maxValidCount = 0;
    for (final loc in eligibleLocations) {
      if (loc.seriousAccidents != null && loc.seriousAccidents! > maxValidCount) {
        maxValidCount = loc.seriousAccidents!;
      }
    }

    if (maxValidCount <= 0) {
      return 0.0;
    }

    double sumLocationRisk = 0.0;

    for (final loc in eligibleLocations) {
      final locationPoint = LatLng(loc.latitude!, loc.longitude!);
      final distanceMeters = HazardAnalysisService.getMinimumDistanceToRoute(
        locationPoint,
        route.polylinePoints,
      );

      if (distanceMeters <= radiusMeters) {
        final double normalizedCount = (loc.seriousAccidents! / maxValidCount).clamp(0.0, 1.0);
        final double proximityFactor = (1.0 - (distanceMeters / radiusMeters)).clamp(0.0, 1.0);
        final double locationRisk = normalizedCount * proximityFactor;
        sumLocationRisk += locationRisk;
      }
    }

    final double historicalRisk = sumLocationRisk.clamp(0.0, 1.0);
    return historicalRisk * maxPenalty;
  }
}
