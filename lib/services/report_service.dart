import 'package:flutter/foundation.dart';
import '../models/hazard_report.dart';
import 'demo_data_service.dart';
import 'supabase_service.dart';

/// Service managing hazard report creation and geographic fetching.
class ReportService {
  /// Fetch active hazard reports from Supabase (with fallback to embedded demo dataset).
  static Future<List<HazardReport>> fetchNearbyReports({
    double? latitude,
    double? longitude,
    double radiusKm = 100.0,
  }) async {
    final client = SupabaseService.instance.client;
    if (client == null) {
      debugPrint('[ReportService] Supabase client unconfigured. Returning demo reports.');
      return DemoDataService.getNagpurDemoReports();
    }

    try {
      // Fetch active hazard reports from Supabase
      final response = await client
          .from('reports')
          .select()
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(200);

      final List data = response as List;
      final reports = data
          .map((map) => HazardReport.fromJson(map as Map<String, dynamic>))
          .toList();

      if (reports.isNotEmpty) {
        return reports;
      }
      return DemoDataService.getNagpurDemoReports();
    } catch (e) {
      debugPrint('[ReportService] Error fetching reports from Supabase ($e). Falling back to demo data.');
      return DemoDataService.getNagpurDemoReports();
    }
  }

  /// Submit a new hazard report to Supabase.
  static Future<bool> submitReport(HazardReport report) async {
    final client = SupabaseService.instance.client;
    if (client == null) {
      throw Exception('Supabase is not configured. Please verify credentials.');
    }

    try {
      final insertData = report.toInsertJson();
      debugPrint('[ReportService] Submitting report: $insertData');
      await client.from('reports').insert(insertData);
      debugPrint('[ReportService] Report submitted successfully.');
      return true;
    } catch (e) {
      debugPrint('[ReportService] Error inserting report: $e');
      throw Exception('Could not submit the report ($e).');
    }
  }

  /// Log route history into Supabase (for future safety analysis).
  static Future<void> saveRouteHistory({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    double? distanceMeters,
    int? durationSeconds,
    Map<String, dynamic>? routeGeometryJson,
    int? safetyScore,
    int? hazardCount,
    String? analysisVersion,
  }) async {
    final client = SupabaseService.instance.client;
    if (client == null) return;

    try {
      final userId = SupabaseService.instance.currentUserId;
      await client.from('route_history').insert({
        if (userId != null) 'user_id': userId,
        'start_latitude': startLat,
        'start_longitude': startLon,
        'end_latitude': endLat,
        'end_longitude': endLon,
        'distance_meters': distanceMeters,
        'duration_seconds': durationSeconds,
        'route_geometry': routeGeometryJson,
        if (safetyScore != null) 'safety_score': safetyScore,
        if (hazardCount != null) 'hazard_count': hazardCount,
        if (analysisVersion != null) 'analysis_version': analysisVersion,
      });
    } catch (e) {
      debugPrint('[ReportService] Non-critical route history logging error: $e');
    }
  }

  /// Confirm an active hazard report (distinct user vote).
  /// Prevented from self-confirmation or duplicate votes by Supabase RLS and unique constraints.
  static Future<bool> confirmReport(String reportId) async {
    final client = SupabaseService.instance.client;
    final userId = SupabaseService.instance.currentUserId;
    if (client == null || userId == null) {
      debugPrint('[ReportService] Auth required to confirm reports.');
      return false;
    }

    try {
      await client.from('report_votes').insert({
        'report_id': reportId,
        'user_id': userId,
        'vote_type': 'confirm',
      });
      debugPrint('[ReportService] Confirmed report $reportId');
      return true;
    } catch (e) {
      debugPrint('[ReportService] Report confirmation rejected (self-vote or duplicate): $e');
      return false;
    }
  }

  /// Mark an active hazard report as no longer present / clear (distinct user vote).
  static Future<bool> clearReport(String reportId) async {
    final client = SupabaseService.instance.client;
    final userId = SupabaseService.instance.currentUserId;
    if (client == null || userId == null) {
      debugPrint('[ReportService] Auth required to clear reports.');
      return false;
    }

    try {
      await client.from('report_votes').insert({
        'report_id': reportId,
        'user_id': userId,
        'vote_type': 'clear',
      });
      debugPrint('[ReportService] Cleared report $reportId');
      return true;
    } catch (e) {
      debugPrint('[ReportService] Clear vote rejected (self-vote or duplicate): $e');
      return false;
    }
  }
}
