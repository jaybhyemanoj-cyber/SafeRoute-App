/// Categorization of OpenStreetMap infrastructure & contextual features.
enum OsmFeatureCategory {
  pedestrianPath,
  livingStreet,
  policeStation,
  medicalFacility,
  commercialShop,
  other,
}

/// Internal model representing an OpenStreetMap feature loaded from export.geojson.
/// Features represent point locations used strictly for internal route safety scoring.
class OsmFeature {
  final String id;
  final double latitude;
  final double longitude;
  final OsmFeatureCategory category;
  final String? name;
  final Map<String, String> tags;

  const OsmFeature({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.name,
    this.tags = const {},
  });

  /// Dedicated pedestrian path (footway, pedestrian street, path, steps).
  bool get isPedestrianPath => category == OsmFeatureCategory.pedestrianPath;

  /// Shared residential low-speed living street.
  bool get isLivingStreet => category == OsmFeatureCategory.livingStreet;

  /// Contextual safety or emergency facility.
  bool get isContextualFacility =>
      category == OsmFeatureCategory.policeStation ||
      category == OsmFeatureCategory.medicalFacility ||
      category == OsmFeatureCategory.commercialShop;
}
