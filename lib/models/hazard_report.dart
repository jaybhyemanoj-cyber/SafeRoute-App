import 'package:flutter/material.dart';

/// Represents a community-reported safety hazard.
class HazardReport {
  final String id;
  final String? userId;
  final double latitude;
  final double longitude;
  final String hazardType;
  final String? description;
  final String? photoUrl;
  final DateTime createdAt;
  final String status;
  final double confidence;

  const HazardReport({
    required this.id,
    this.userId,
    required this.latitude,
    required this.longitude,
    required this.hazardType,
    this.description,
    this.photoUrl,
    required this.createdAt,
    this.status = 'active',
    this.confidence = 0.5,
  });

  /// Check if this report is a synthetic demo data record for testing.
  bool get isDemo =>
      id.startsWith('demo-') ||
      id.startsWith('d0000000-') ||
      (description != null && description!.toUpperCase().contains('[DEMO'));

  /// Get user-facing clean description (stripping any demo tag prefix).
  String get displayDescription {
    if (description == null) return '';
    final clean = description!
        .replaceAll(RegExp(r'\[DEMO DATA\s*—\s*NOT A REAL INCIDENT\]\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\[DEMO DATA\]\s*', caseSensitive: false), '')
        .trim();
    return clean;
  }

  /// Factory constructor to parse JSON from Supabase.
  factory HazardReport.fromJson(Map<String, dynamic> json) {
    return HazardReport(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      hazardType: json['hazard_type']?.toString() ?? 'other',
      description: json['description']?.toString(),
      photoUrl: json['photo_url']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: json['status']?.toString() ?? 'active',
      confidence: json['confidence'] != null
          ? (json['confidence'] as num).toDouble()
          : 0.5,
    );
  }

  /// Convert model instance to JSON for Supabase insertion.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'hazard_type': hazardType,
      'description': description,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
      'status': status,
      'confidence': confidence,
    };
  }

  /// Convert model instance to JSON formatted specifically for DB insertion,
  /// omitting client-side temporary IDs if they are not valid UUIDs.
  Map<String, dynamic> toInsertJson() {
    final Map<String, dynamic> data = {
      if (userId != null) 'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'hazard_type': hazardType,
      if (description != null) 'description': description,
      if (photoUrl != null) 'photo_url': photoUrl,
      'status': status,
      'confidence': confidence,
    };
    if (RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(id)) {
      data['id'] = id;
    }
    return data;
  }


  /// Available hazard categories with internal keys, display labels, and icons.
  static const List<Map<String, dynamic>> hazardCategories = [
    {
      'key': 'poor_lighting',
      'label': 'Poor Lighting',
      'icon': Icons.lightbulb_outline_rounded,
      'emoji': '💡',
    },
    {
      'key': 'broken_footpath',
      'label': 'Broken Footpath',
      'icon': Icons.directions_walk_rounded,
      'emoji': '🚶',
    },
    {
      'key': 'road_damage',
      'label': 'Road Damage',
      'icon': Icons.warning_amber_rounded,
      'emoji': '🛣',
    },
    {
      'key': 'construction',
      'label': 'Construction',
      'icon': Icons.engineering_rounded,
      'emoji': '🚧',
    },
    {
      'key': 'unsafe_crossing',
      'label': 'Unsafe Crossing',
      'icon': Icons.alt_route_rounded,
      'emoji': '🚦',
    },
    {
      'key': 'heavy_traffic',
      'label': 'Heavy Traffic',
      'icon': Icons.directions_car_rounded,
      'emoji': '🚗',
    },
    {
      'key': 'waterlogging',
      'label': 'Waterlogging',
      'icon': Icons.water_drop_rounded,
      'emoji': '💧',
    },
    {
      'key': 'suspicious_activity',
      'label': 'Suspicious Activity',
      'icon': Icons.remove_red_eye_rounded,
      'emoji': '👁',
    },
    {
      'key': 'stray_animals',
      'label': 'Stray Animals',
      'icon': Icons.pets_rounded,
      'emoji': '🐕',
    },
    {
      'key': 'other',
      'label': 'Other',
      'icon': Icons.error_outline_rounded,
      'emoji': '⚠️',
    },
  ];

  /// Get user-friendly display label for this report's hazard type.
  String get displayLabel {
    final match = hazardCategories.firstWhere(
      (cat) => cat['key'] == hazardType,
      orElse: () => {'label': 'Hazard'},
    );
    return match['label'] as String;
  }

  /// Get IconData for this report's hazard type.
  IconData get iconData {
    final match = hazardCategories.firstWhere(
      (cat) => cat['key'] == hazardType,
      orElse: () => {'icon': Icons.warning_rounded},
    );
    return match['icon'] as IconData;
  }

  /// Get Emoji icon for this report's hazard type.
  String get emoji {
    final match = hazardCategories.firstWhere(
      (cat) => cat['key'] == hazardType,
      orElse: () => {'emoji': '⚠️'},
    );
    return match['emoji'] as String;
  }
}
