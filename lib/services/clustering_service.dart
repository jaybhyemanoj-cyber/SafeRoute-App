import 'package:latlong2/latlong.dart';
import '../models/hazard_report.dart';

/// Represents a spatial/temporal cluster of community reports for the same physical hazard (Phase 6).
class ReportCluster {
  final String clusterId;
  final String categoryKey;
  final LatLng centroid;
  final List<HazardReport> reports;
  final double aggregatedConfidence;
  final DateTime newestReportTime;

  const ReportCluster({
    required this.clusterId,
    required this.categoryKey,
    required this.centroid,
    required this.reports,
    required this.aggregatedConfidence,
    required this.newestReportTime,
  });
}

/// Service for grouping duplicate community reports within spatial proximity (Phase 6).
class ClusteringService {
  /// Proximity threshold in meters to consider reports as part of the same physical hazard cluster.
  static const double clusterRadiusMeters = 50.0;

  /// Cluster a list of reports by spatial proximity & hazard type to prevent penalty double-counting.
  static List<ReportCluster> clusterReports(List<HazardReport> reports) {
    if (reports.isEmpty) return [];

    final distanceCalc = const Distance();
    final List<ReportCluster> clusters = [];
    final Set<String> processedReportIds = {};

    for (final report in reports) {
      if (processedReportIds.contains(report.id)) continue;

      final reportPos = LatLng(report.latitude, report.longitude);
      final List<HazardReport> clusterMembers = [report];
      processedReportIds.add(report.id);

      // Find other reports within 50m of same hazard type
      for (final other in reports) {
        if (processedReportIds.contains(other.id)) continue;
        if (other.hazardType != report.hazardType) continue;

        final otherPos = LatLng(other.latitude, other.longitude);
        final dist = distanceCalc.as(LengthUnit.Meter, reportPos, otherPos);

        if (dist <= clusterRadiusMeters) {
          clusterMembers.add(other);
          processedReportIds.add(other.id);
        }
      }

      // Calculate centroid coordinate
      double avgLat = 0;
      double avgLng = 0;
      for (final m in clusterMembers) {
        avgLat += m.latitude;
        avgLng += m.longitude;
      }
      avgLat /= clusterMembers.length;
      avgLng /= clusterMembers.length;

      // Aggregated confidence formula: capped increase per independent report
      // e.g. 1 report = 0.5, 2 reports = 0.7, 3+ reports = 0.9 (max 1.0)
      double baseConf = clusterMembers.first.confidence;
      if (clusterMembers.length > 1) {
        baseConf = (baseConf + (clusterMembers.length - 1) * 0.2).clamp(0.0, 1.0);
      }

      DateTime newest = clusterMembers.first.createdAt;
      for (final m in clusterMembers) {
        if (m.createdAt.isAfter(newest)) newest = m.createdAt;
      }

      clusters.add(
        ReportCluster(
          clusterId: 'cluster_${report.id}',
          categoryKey: report.hazardType,
          centroid: LatLng(avgLat, avgLng),
          reports: clusterMembers,
          aggregatedConfidence: baseConf,
          newestReportTime: newest,
        ),
      );
    }

    return clusters;
  }
}
