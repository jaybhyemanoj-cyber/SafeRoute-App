import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/hazard_report.dart';
import '../theme/app_colors.dart';

/// Custom map marker widget displaying a reported hazard.
class HazardMarkerWidget extends StatelessWidget {
  final HazardReport report;
  final VoidCallback onTap;

  const HazardMarkerWidget({
    super.key,
    required this.report,
    required this.onTap,
  });

  /// Build a flutter_map Marker instance.
  static Marker buildMarker({
    required HazardReport report,
    required VoidCallback onTap,
  }) {
    return Marker(
      point: LatLng(report.latitude, report.longitude),
      width: 30,
      height: 30,
      alignment: Alignment.center,
      child: HazardMarkerWidget(
        report: report,
        onTap: onTap,
      ),
    );
  }

  /// Get color tint for specific hazard type.
  Color _getHazardColor(String hazardType) {
    switch (hazardType) {
      case 'poor_lighting':
        return const Color(0xFFD97706); // Warm Amber
      case 'construction':
      case 'road_damage':
      case 'broken_footpath':
        return const Color(0xFFEA580C); // Muted Orange
      case 'waterlogging':
      case 'heavy_traffic':
        return const Color(0xFF2563EB); // Soft Blue
      case 'suspicious_activity':
      case 'unsafe_crossing':
        return const Color(0xFFDC2626); // Alert Coral
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _getHazardColor(report.hazardType);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: accentColor,
            width: 2.0,
          ),
          boxShadow: AppColors.softShadow,
        ),
        child: Center(
          child: Icon(
            report.iconData,
            size: 16,
            color: accentColor,
          ),
        ),
      ),
    );
  }
}
