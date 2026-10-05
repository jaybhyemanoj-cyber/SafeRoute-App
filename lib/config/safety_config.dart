/// Centralized configuration for the SafeRoute AI Safety Analysis Engine & Navigation (Phase 3 & Phase 4).
class SafetyConfig {
  /// Algorithm version identifier for scoring record audits.
  static const String analysisVersion = 'safety_engine_v1';

  /// Base penalty values per hazard category (0-100 scale impact).
  static const Map<String, double> hazardWeights = {
    'poor_lighting': 10.0,
    'broken_footpath': 8.0,
    'road_damage': 7.0,
    'construction': 8.0,
    'unsafe_crossing': 12.0,
    'heavy_traffic': 10.0,
    'waterlogging': 8.0,
    'suspicious_activity': 12.0,
    'stray_animals': 5.0,
    'other': 5.0,
  };

  /// Recency decay multipliers by report age.
  static double getRecencyWeight(DateTime createdAt) {
    final age = DateTime.now().difference(createdAt);
    if (age.inHours <= 24) return 1.0; // 0-24 hrs: 100% influence
    if (age.inDays <= 3) return 0.8;   // 1-3 days: 80% influence
    if (age.inDays <= 7) return 0.6;   // 4-7 days: 60% influence
    if (age.inDays <= 30) return 0.3;  // 8-30 days: 30% influence
    return 0.05;                       // 30+ days: minimal influence
  }

  /// Proximity weight multipliers by distance from route polyline in meters.
  static double getProximityWeight(double distanceMeters) {
    if (distanceMeters <= 50.0) return 1.0;  // 0-50m: High influence
    if (distanceMeters <= 100.0) return 0.7; // 50-100m: Medium influence
    if (distanceMeters <= 200.0) return 0.35;// 100-200m: Low influence
    return 0.0;                              // 200m+: No penalty
  }

  /// Capped density penalty per hazard category cluster to prevent infinite penalty buildup.
  static const double maxCategoryPenalty = 25.0;

  /// Maximum penalty deductible for route distance trade-off (excess length).
  static const double maxDistancePenalty = 20.0;

  /// Distance difference threshold (10% excess allowed before applying penalty).
  static const double distanceToleranceRatio = 0.10;

  /// Configurable radius in meters to evaluate verified historical accident locations.
  static const double historicalSearchRadiusMeters = 100.0;

  /// Configurable maximum penalty points (0-15 scale) applied for historical risk.
  static const double maxHistoricalPenalty = 15.0;

  /// Configurable radius in meters to evaluate OpenStreetMap infrastructure & contextual features.
  static const double osmFeatureSearchRadiusMeters = 100.0;

  /// Maximum positive bonus points granted for mapped pedestrian infrastructure.
  static const double maxOsmPedestrianBonus = 5.0;

  /// Maximum positive bonus points granted for contextual safety facilities (police/medical/shops).
  static const double maxOsmContextualBonus = 5.0;

  // --- Phase 4 Automated Trust System Configuration Parameters ---

  /// Configurable automatic report expiry durations by hazard category.
  static const Map<String, Duration> hazardExpiryDurations = {
    'stray_animals': Duration(hours: 24),        // 1 day
    'heavy_traffic': Duration(hours: 48),        // 2 days
    'waterlogging': Duration(hours: 48),         // 2 days
    'suspicious_activity': Duration(hours: 72),  // 3 days
    'poor_lighting': Duration(days: 7),          // 7 days
    'unsafe_crossing': Duration(days: 7),        // 7 days
    'broken_footpath': Duration(days: 14),       // 14 days
    'road_damage': Duration(days: 14),           // 14 days
    'construction': Duration(days: 14),          // 14 days
    'other': Duration(days: 7),                  // 7 days
  };

  /// Check if a report has expired based on its hazard type and creation timestamp.
  static bool isReportExpired(String hazardType, DateTime createdAt) {
    final maxDuration = hazardExpiryDurations[hazardType] ?? const Duration(days: 7);
    return DateTime.now().difference(createdAt) > maxDuration;
  }

  /// Number of distinct user confirmations required for the 'Community-confirmed' label.
  static const int requiredConfirmationsForConfirmedLabel = 2;

  /// Mandatory safety information disclaimer required across Phase 4.
  static const String trustSystemDisclaimer =
      'Safety information is based on available map data and community reports. Route safety is not guaranteed. Conditions may change; stay alert and use your own judgment.';




  // --- Phase 4 Live Navigation Configuration Parameters ---

  /// Distance threshold in meters to trigger an upcoming hazard proximity warning banner (e.g. 150m).
  static const double hazardAlertDistanceMeters = 150.0;

  /// Minimum distance in meters user must travel before refreshing nearby hazard queries.
  static const double hazardRefreshDistanceMeters = 50.0;

  /// Minimum time interval in seconds before re-fetching nearby community hazard reports.
  static const int hazardRefreshIntervalSeconds = 15;

  /// Distance deviation in meters from route polyline to trigger off-route evaluation.
  static const double offRouteThresholdMeters = 35.0;

  /// Cooldown period in seconds between automatic rerouting attempts to prevent GPS jitter loops.
  static const int rerouteCooldownSeconds = 15;

  /// Maximum acceptable GPS accuracy in meters to allow rerouting or location updates.
  static const double gpsAccuracyThresholdMeters = 30.0;

  /// Radius in meters from destination coordinate to confirm walking arrival.
  static const double arrivalRadiusMeters = 20.0;
}
