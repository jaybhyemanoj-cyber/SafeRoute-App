/// Represents user safety and routing preferences in public.user_preferences (Phase 6).
class UserPreferences {
  final String userId;
  final String routePreferenceMode; // 'balanced', 'safety_priority', 'time_priority'
  final bool avoidHeavyTraffic;
  final bool avoidBrokenFootpaths;
  final bool avoidConstruction;
  final bool avoidWaterlogging;
  final bool avoidUnsafeCrossings;
  final bool avoidRoadDamage;
  final bool avoidSuspiciousActivity;
  final bool avoidStrayAnimals;
  final String alertSensitivity; // 'low', 'medium', 'high'
  final bool aiInsightsEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserPreferences({
    required this.userId,
    this.routePreferenceMode = 'balanced',
    this.avoidHeavyTraffic = false,
    this.avoidBrokenFootpaths = false,
    this.avoidConstruction = false,
    this.avoidWaterlogging = false,
    this.avoidUnsafeCrossings = false,
    this.avoidRoadDamage = false,
    this.avoidSuspiciousActivity = false,
    this.avoidStrayAnimals = false,
    this.alertSensitivity = 'medium',
    this.aiInsightsEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserPreferences.defaultPreferences(String userId) {
    final now = DateTime.now();
    return UserPreferences(
      userId: userId,
      routePreferenceMode: 'balanced',
      avoidHeavyTraffic: false,
      avoidBrokenFootpaths: false,
      avoidConstruction: false,
      avoidWaterlogging: false,
      avoidUnsafeCrossings: false,
      avoidRoadDamage: false,
      avoidSuspiciousActivity: false,
      avoidStrayAnimals: false,
      alertSensitivity: 'medium',
      aiInsightsEnabled: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      userId: json['user_id']?.toString() ?? '',
      routePreferenceMode: json['route_preference_mode']?.toString() ?? 'balanced',
      avoidHeavyTraffic: json['avoid_heavy_traffic'] == true,
      avoidBrokenFootpaths: json['avoid_broken_footpaths'] == true,
      avoidConstruction: json['avoid_construction'] == true,
      avoidWaterlogging: json['avoid_waterlogging'] == true,
      avoidUnsafeCrossings: json['avoid_unsafe_crossings'] == true,
      avoidRoadDamage: json['avoid_road_damage'] == true,
      avoidSuspiciousActivity: json['avoid_suspicious_activity'] == true,
      avoidStrayAnimals: json['avoid_stray_animals'] == true,
      alertSensitivity: json['alert_sensitivity']?.toString() ?? 'medium',
      aiInsightsEnabled: json['ai_insights_enabled'] != false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'route_preference_mode': routePreferenceMode,
        'avoid_heavy_traffic': avoidHeavyTraffic,
        'avoid_broken_footpaths': avoidBrokenFootpaths,
        'avoid_construction': avoidConstruction,
        'avoid_waterlogging': avoidWaterlogging,
        'avoid_unsafe_crossings': avoidUnsafeCrossings,
        'avoid_road_damage': avoidRoadDamage,
        'avoid_suspicious_activity': avoidSuspiciousActivity,
        'avoid_stray_animals': avoidStrayAnimals,
        'alert_sensitivity': alertSensitivity,
        'ai_insights_enabled': aiInsightsEnabled,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  UserPreferences copyWith({
    String? userId,
    String? routePreferenceMode,
    bool? avoidHeavyTraffic,
    bool? avoidBrokenFootpaths,
    bool? avoidConstruction,
    bool? avoidWaterlogging,
    bool? avoidUnsafeCrossings,
    bool? avoidRoadDamage,
    bool? avoidSuspiciousActivity,
    bool? avoidStrayAnimals,
    String? alertSensitivity,
    bool? aiInsightsEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPreferences(
      userId: userId ?? this.userId,
      routePreferenceMode: routePreferenceMode ?? this.routePreferenceMode,
      avoidHeavyTraffic: avoidHeavyTraffic ?? this.avoidHeavyTraffic,
      avoidBrokenFootpaths: avoidBrokenFootpaths ?? this.avoidBrokenFootpaths,
      avoidConstruction: avoidConstruction ?? this.avoidConstruction,
      avoidWaterlogging: avoidWaterlogging ?? this.avoidWaterlogging,
      avoidUnsafeCrossings: avoidUnsafeCrossings ?? this.avoidUnsafeCrossings,
      avoidRoadDamage: avoidRoadDamage ?? this.avoidRoadDamage,
      avoidSuspiciousActivity: avoidSuspiciousActivity ?? this.avoidSuspiciousActivity,
      avoidStrayAnimals: avoidStrayAnimals ?? this.avoidStrayAnimals,
      alertSensitivity: alertSensitivity ?? this.alertSensitivity,
      aiInsightsEnabled: aiInsightsEnabled ?? this.aiInsightsEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if a given hazard category matches user's avoidance preference.
  bool isHazardCategoryAvoided(String categoryKey) {
    switch (categoryKey) {
      case 'heavy_traffic':
        return avoidHeavyTraffic;
      case 'broken_footpath':
        return avoidBrokenFootpaths;
      case 'construction':
        return avoidConstruction;
      case 'waterlogging':
        return avoidWaterlogging;
      case 'unsafe_crossing':
        return avoidUnsafeCrossings;
      case 'road_damage':
        return avoidRoadDamage;
      case 'suspicious_activity':
        return avoidSuspiciousActivity;
      case 'stray_animals':
        return avoidStrayAnimals;
      default:
        return false;
    }
  }
}
