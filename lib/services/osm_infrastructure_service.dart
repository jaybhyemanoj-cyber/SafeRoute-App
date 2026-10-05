import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:latlong2/latlong.dart';
import '../config/safety_config.dart';
import '../models/osm_feature.dart';
import '../models/route_model.dart';
import 'hazard_analysis_service.dart';

/// Result container for OpenStreetMap infrastructure & contextual score adjustments.
class OsmScoreAdjustments {
  final double pedestrianBonus;
  final double livingStreetBonus;
  final double contextualBonus;
  final int pedestrianPathCount;
  final int livingStreetCount;
  final int policeStationCount;
  final int medicalFacilityCount;
  final int commercialShopCount;

  const OsmScoreAdjustments({
    required this.pedestrianBonus,
    required this.livingStreetBonus,
    required this.contextualBonus,
    required this.pedestrianPathCount,
    required this.livingStreetCount,
    required this.policeStationCount,
    required this.medicalFacilityCount,
    required this.commercialShopCount,
  });

  /// Total positive infrastructure bonus (capped).
  double get totalInfrastructureBonus => (pedestrianBonus + livingStreetBonus).clamp(0.0, 5.0);

  /// Total positive contextual bonus (capped).
  double get totalContextualBonus => contextualBonus.clamp(0.0, 5.0);
}

/// Service for loading, caching, and evaluating OpenStreetMap export.geojson infrastructure & contextual features.
/// Data is processed internally for route scoring only — raw features and coordinates are never exposed in UI.
/// OpenStreetMap Attribution: Data (c) OpenStreetMap contributors.
class OsmInfrastructureService {
  static const String _defaultGeoJsonPath = 'assets/data/export.geojson';
  static List<OsmFeature>? _cachedFeatures;

  /// Load and parse export.geojson features into memory with caching.
  static Future<List<OsmFeature>> loadFeatures({String? customGeoJsonPath, String? rawJsonString}) async {
    if (_cachedFeatures != null && customGeoJsonPath == null && rawJsonString == null) {
      return _cachedFeatures!;
    }

    try {
      final jsonString = rawJsonString ??
          await rootBundle.loadString(customGeoJsonPath ?? _defaultGeoJsonPath);
      final features = parseGeoJson(jsonString);
      if (customGeoJsonPath == null && rawJsonString == null) {
        _cachedFeatures = features;
      }
      return features;
    } catch (_) {
      return [];
    }
  }

  /// Parse GeoJSON string into structured [OsmFeature] objects.
  static List<OsmFeature> parseGeoJson(String geoJsonContent) {
    final List<OsmFeature> features = [];
    try {
      final data = jsonDecode(geoJsonContent) as Map<String, dynamic>;
      final rawFeatures = data['features'] as List?;
      if (rawFeatures == null) return features;

      for (int i = 0; i < rawFeatures.length; i++) {
        final feat = rawFeatures[i] as Map<String, dynamic>?;
        if (feat == null) continue;

        final geom = feat['geometry'] as Map<String, dynamic>?;
        if (geom == null || geom['type'] != 'Point') continue;

        final coords = geom['coordinates'] as List?;
        if (coords == null || coords.length < 2) continue;

        final num? lonNum = coords[0] as num?;
        final num? latNum = coords[1] as num?;
        if (lonNum == null || latNum == null) continue;

        final double lon = lonNum.toDouble();
        final double lat = latNum.toDouble();

        if (lat < -90.0 || lat > 90.0 || lon < -180.0 || lon > 180.0) continue;

        final props = (feat['properties'] as Map<String, dynamic>?) ?? {};
        final String id = props['@id']?.toString() ?? feat['id']?.toString() ?? '$i';
        final String? name = props['name']?.toString();

        final Map<String, String> tags = {};
        props.forEach((k, v) {
          if (v != null) tags[k] = v.toString();
        });

        final category = classifyFeature(tags);

        features.add(
          OsmFeature(
            id: id,
            latitude: lat,
            longitude: lon,
            category: category,
            name: name,
            tags: tags,
          ),
        );
      }
    } catch (_) {}

    return features;
  }

  /// Classify OpenStreetMap tags into specific feature categories.
  static OsmFeatureCategory classifyFeature(Map<String, String> tags) {
    final highway = tags['highway'];
    final amenity = tags['amenity'];
    final shop = tags['shop'];
    final healthcare = tags['healthcare'];

    // 1. Pedestrian paths
    if (highway == 'footway' || highway == 'pedestrian' || highway == 'path' || highway == 'steps') {
      return OsmFeatureCategory.pedestrianPath;
    }

    // 2. Living streets (shared low-speed residential streets)
    if (highway == 'living_street') {
      return OsmFeatureCategory.livingStreet;
    }

    // 3. Police stations
    if (amenity == 'police') {
      return OsmFeatureCategory.policeStation;
    }

    // 4. Medical facilities (hospitals, clinics, doctors)
    if (amenity == 'hospital' || amenity == 'clinic' || amenity == 'doctors' || healthcare != null) {
      return OsmFeatureCategory.medicalFacility;
    }

    // 5. Commercial shops
    if (shop != null ||
        amenity == 'pharmacy' ||
        amenity == 'bank' ||
        amenity == 'atm' ||
        amenity == 'fuel' ||
        amenity == 'marketplace' ||
        amenity == 'restaurant' ||
        amenity == 'cafe' ||
        amenity == 'fast_food' ||
        amenity == 'supermarket') {
      return OsmFeatureCategory.commercialShop;
    }

    return OsmFeatureCategory.other;
  }

  /// Filter features that fall within [radiusMeters] of a route polyline.
  static List<OsmFeature> findNearbyFeatures({
    required RouteModel route,
    required List<OsmFeature> features,
    double radiusMeters = SafetyConfig.osmFeatureSearchRadiusMeters,
  }) {
    if (route.polylinePoints.isEmpty || features.isEmpty) {
      return [];
    }

    final List<OsmFeature> nearby = [];
    for (final feat in features) {
      final distance = HazardAnalysisService.getMinimumDistanceToRoute(
        LatLng(feat.latitude, feat.longitude),
        route.polylinePoints,
      );
      if (distance <= radiusMeters) {
        nearby.add(feat);
      }
    }
    return nearby;
  }

  /// Calculate positive infrastructure & contextual score adjustments.
  /// Rules:
  /// - Dedicated pedestrian paths provide modest positive bonus (capped by SafetyConfig.maxOsmPedestrianBonus).
  /// - Living streets provide small shared road bonus (capped at 2.0).
  /// - Contextual facilities provide modest positive presence bonus (capped by SafetyConfig.maxOsmContextualBonus).
  /// - Missing mapped footpaths/streetlights mean "unknown" (0 bonus, NEVER a penalty).
  /// - Contextual presence NEVER guarantees safety or overrides community hazard penalties.
  static OsmScoreAdjustments calculateOsmScoreAdjustments({
    required RouteModel route,
    required List<OsmFeature> features,
    double radiusMeters = SafetyConfig.osmFeatureSearchRadiusMeters,
  }) {
    final nearby = findNearbyFeatures(route: route, features: features, radiusMeters: radiusMeters);

    int pedestrianPathCount = 0;
    int livingStreetCount = 0;
    int policeCount = 0;
    int medicalCount = 0;
    int shopCount = 0;

    for (final feat in nearby) {
      switch (feat.category) {
        case OsmFeatureCategory.pedestrianPath:
          pedestrianPathCount++;
          break;
        case OsmFeatureCategory.livingStreet:
          livingStreetCount++;
          break;
        case OsmFeatureCategory.policeStation:
          policeCount++;
          break;
        case OsmFeatureCategory.medicalFacility:
          medicalCount++;
          break;
        case OsmFeatureCategory.commercialShop:
          shopCount++;
          break;
        case OsmFeatureCategory.other:
          break;
      }
    }

    // Positive infrastructure bonuses
    final double pedestrianBonus = (pedestrianPathCount * 1.0)
        .clamp(0.0, SafetyConfig.maxOsmPedestrianBonus);
    final double livingStreetBonus = (livingStreetCount * 0.5)
        .clamp(0.0, 2.0);

    // Contextual facility bonuses (modest presence signal, not proof of safety)
    final double rawContextual = (policeCount * 2.0) + (medicalCount * 0.5) + (shopCount * 0.2);
    final double contextualBonus = rawContextual.clamp(0.0, SafetyConfig.maxOsmContextualBonus);

    return OsmScoreAdjustments(
      pedestrianBonus: pedestrianBonus,
      livingStreetBonus: livingStreetBonus,
      contextualBonus: contextualBonus,
      pedestrianPathCount: pedestrianPathCount,
      livingStreetCount: livingStreetCount,
      policeStationCount: policeCount,
      medicalFacilityCount: medicalCount,
      commercialShopCount: shopCount,
    );
  }
}
