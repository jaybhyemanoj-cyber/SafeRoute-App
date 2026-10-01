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
    final isDemo = report.isDemo;
    return Marker(
      point: LatLng(report.latitude, report.longitude),
      width: isDemo ? 54 : 44,
      height: isDemo ? 54 : 44,
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
    final isDemo = report.isDemo;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDemo ? Colors.purple.shade600 : accentColor,
                width: isDemo ? 3.0 : 2.5,
              ),
              boxShadow: AppColors.softShadow,
            ),
            child: Center(
              child: Icon(
                report.iconData,
                size: 20,
                color: isDemo ? Colors.purple.shade700 : accentColor,
              ),
            ),
          ),
          if (isDemo)
            Positioned(
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.purple.shade700,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'DEMO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
