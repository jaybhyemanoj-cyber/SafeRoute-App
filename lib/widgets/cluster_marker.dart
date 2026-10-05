import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/hazard_report.dart';
import '../theme/app_colors.dart';

class HazardCluster {
  final LatLng center;
  final List<HazardReport> reports;

  HazardCluster({required this.center, required this.reports});

  int get count => reports.length;
}

class ClusterHelper {
  /// Aggregates hazard reports into clusters based on map camera projection or lat/lon proximity.
  static List<HazardCluster> buildClusters({
    required List<HazardReport> reports,
    required MapCamera? camera,
    double clusterRadiusPx = 45.0,
  }) {
    if (reports.isEmpty) return [];

    // If camera is not yet initialized (e.g. before initial FlutterMap render), cluster by fixed coordinate distance
    if (camera == null) {
      return _buildInitialCoordinateClusters(reports);
    }

    // At detailed zoom level (>= 16), show individual markers without clustering
    if (camera.zoom >= 16.0) {
      return reports
          .map((r) => HazardCluster(
                center: LatLng(r.latitude, r.longitude),
                reports: [r],
              ))
          .toList();
    }

    final List<HazardCluster> clusters = [];

    for (final report in reports) {
      final reportPoint = LatLng(report.latitude, report.longitude);
      final reportPx = camera.project(reportPoint);

      HazardCluster? nearestCluster;
      double minDistance = double.infinity;

      for (final cluster in clusters) {
        final clusterPx = camera.project(cluster.center);
        final dx = reportPx.x - clusterPx.x;
        final dy = reportPx.y - clusterPx.y;
        final dist = sqrt(dx * dx + dy * dy);

        if (dist < clusterRadiusPx && dist < minDistance) {
          minDistance = dist;
          nearestCluster = cluster;
        }
      }

      if (nearestCluster != null) {
        nearestCluster.reports.add(report);
        double sumLat = 0;
        double sumLon = 0;
        for (final r in nearestCluster.reports) {
          sumLat += r.latitude;
          sumLon += r.longitude;
        }
        final newCenter = LatLng(
          sumLat / nearestCluster.reports.length,
          sumLon / nearestCluster.reports.length,
        );
        final idx = clusters.indexOf(nearestCluster);
        clusters[idx] = HazardCluster(
          center: newCenter,
          reports: nearestCluster.reports,
        );
      } else {
        clusters.add(HazardCluster(
          center: reportPoint,
          reports: [report],
        ));
      }
    }

    return clusters;
  }

  static List<HazardCluster> _buildInitialCoordinateClusters(List<HazardReport> reports) {
    final List<HazardCluster> clusters = [];
    const double threshold = 0.003;

    for (final report in reports) {
      final point = LatLng(report.latitude, report.longitude);
      HazardCluster? nearest;
      double minD = double.infinity;

      for (final cluster in clusters) {
        final dLat = point.latitude - cluster.center.latitude;
        final dLon = point.longitude - cluster.center.longitude;
        final d = sqrt(dLat * dLat + dLon * dLon);
        if (d < threshold && d < minD) {
          minD = d;
          nearest = cluster;
        }
      }

      if (nearest != null) {
        nearest.reports.add(report);
        double sumLat = 0;
        double sumLon = 0;
        for (final r in nearest.reports) {
          sumLat += r.latitude;
          sumLon += r.longitude;
        }
        final idx = clusters.indexOf(nearest);
        clusters[idx] = HazardCluster(
          center: LatLng(sumLat / nearest.reports.length, sumLon / nearest.reports.length),
          reports: nearest.reports,
        );
      } else {
        clusters.add(HazardCluster(center: point, reports: [report]));
      }
    }

    return clusters;
  }
}

class ClusterMarkerWidget extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const ClusterMarkerWidget({
    super.key,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: AppColors.softShadow,
        ),
        child: Center(
          child: Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
