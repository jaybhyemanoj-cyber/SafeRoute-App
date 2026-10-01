import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Lightweight turn-by-turn navigation instruction model parsed from OSRM steps.
class NavigationInstruction {
  final String type;
  final String? modifier;
  final String streetName;
  final double distanceMeters;
  final double durationSeconds;
  final LatLng location;

  const NavigationInstruction({
    required this.type,
    this.modifier,
    required this.streetName,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.location,
  });

  /// Readable instruction string e.g. "Turn left onto Main Road"
  String get formattedText {
    if (type == 'depart') {
      return streetName.isNotEmpty ? 'Head out on $streetName' : 'Start walking along path';
    }
    if (type == 'arrive') {
      return 'Arrive at destination';
    }

    final modStr = _formatModifier(modifier);
    if (streetName.isNotEmpty && streetName != 'Unnamed Path') {
      return '$modStr onto $streetName';
    }
    return modStr;
  }

  /// Formatted maneuver distance string e.g. "in 180 m"
  String get formattedDistance {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceMeters.round()} m';
  }

  /// Appropriate icon representation for maneuver modifier
  IconData get icon {
    switch (type) {
      case 'depart':
        return Icons.navigation_rounded;
      case 'arrive':
        return Icons.location_on_rounded;
      default:
        break;
    }

    final mod = (modifier ?? '').toLowerCase();
    if (mod.contains('slight left')) return Icons.turn_slight_left_rounded;
    if (mod.contains('sharp left')) return Icons.turn_sharp_left_rounded;
    if (mod.contains('left')) return Icons.turn_left_rounded;
    if (mod.contains('slight right')) return Icons.turn_slight_right_rounded;
    if (mod.contains('sharp right')) return Icons.turn_sharp_right_rounded;
    if (mod.contains('right')) return Icons.turn_right_rounded;
    if (mod.contains('straight')) return Icons.straight_rounded;

    return Icons.navigation_rounded;
  }

  static String _formatModifier(String? mod) {
    switch (mod?.toLowerCase()) {
      case 'left':
        return 'Turn left';
      case 'right':
        return 'Turn right';
      case 'slight left':
        return 'Slight left';
      case 'slight right':
        return 'Slight right';
      case 'sharp left':
        return 'Sharp left';
      case 'sharp right':
        return 'Sharp right';
      case 'straight':
        return 'Continue straight';
      default:
        return 'Continue walking';
    }
  }
}
