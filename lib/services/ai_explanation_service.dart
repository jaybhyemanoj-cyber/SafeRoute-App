import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/ai_config.dart';
import '../models/ai_explanation_response.dart';
import '../models/safety_score.dart';
import '../models/route_candidate.dart';
import '../models/hazard_report.dart';
import '../models/trip_summary.dart';

/// Secure AI Explanation Service communicating with backend proxy server.
class AiExplanationService {
  static final Map<String, AiExplanationResponse> _cache = {};

  /// Explain a single route safety score.
  static Future<AiExplanationResponse> explainRouteScore({
    required SafetyScore safetyScore,
    required double distanceMeters,
    required double durationSeconds,
    required String routeId,
  }) async {
    // 1. Check feature toggle
    if (!AiConfig.aiInsightsEnabled) {
      return AiExplanationResponse.fallback(
        score: safetyScore.overallScore,
        deterministicBullets: safetyScore.whyBulletPoints,
      );
    }

    // 2. Check cache
    final cacheKey = 'route_${routeId}_${safetyScore.overallScore}_${safetyScore.signals.length}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final payload = {
        'route_id': routeId,
        'safety_score': safetyScore.overallScore,
        'distance_km': (distanceMeters / 1000).toStringAsFixed(1),
        'duration_min': (durationSeconds / 60).round(),
        'signals': safetyScore.signals
            .map((s) => {
                  'category': s.hazardType,
                  'label': s.label,
                  'penalty': s.penalty.toStringAsFixed(1),
                  'summary': s.formattedSummary,
                })
            .toList(),
      };

      final response = await http
          .post(
            Uri.parse('${AiConfig.backendUrl}/api/explain-route'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(AiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['error'] != true) {
          final res = AiExplanationResponse.fromJson(data);
          _cache[cacheKey] = res;
          return res;
        }
      }
    } catch (e) {
      debugPrint('[AiExplanationService] Backend request failed ($e). Using local fallback.');
    }

    // Fallback on network/API failure
    final fallback = AiExplanationResponse.fallback(
      score: safetyScore.overallScore,
      deterministicBullets: safetyScore.whyBulletPoints,
    );
    _cache[cacheKey] = fallback;
    return fallback;
  }

  /// Explain tradeoffs between multiple candidate routes.
  static Future<AiExplanationResponse> explainRouteComparison({
    required List<RouteCandidate> candidates,
  }) async {
    if (!AiConfig.aiInsightsEnabled || candidates.isEmpty) {
      final primary = candidates.first;
      return AiExplanationResponse.fallback(
        score: primary.safetyScore.overallScore,
        deterministicBullets: primary.safetyScore.whyBulletPoints,
      );
    }

    try {
      final payload = {
        'candidates': candidates
            .map((c) => {
                  'id': c.id,
                  'title': c.title,
                  'distance_km': (c.route.distanceMeters / 1000).toStringAsFixed(1),
                  'duration_min': (c.route.durationSeconds / 60).round(),
                  'safety_score': c.safetyScore.overallScore,
                  'signals': c.safetyScore.signals.map((s) => s.label).toList(),
                })
            .toList(),
      };

      final response = await http
          .post(
            Uri.parse('${AiConfig.backendUrl}/api/explain-comparison'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(AiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['error'] != true) {
          return AiExplanationResponse.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('[AiExplanationService] Comparison request failed ($e).');
    }

    return AiExplanationResponse.fallback(
      score: candidates.first.safetyScore.overallScore,
      deterministicBullets: candidates.first.safetyScore.whyBulletPoints,
    );
  }

  /// Explain a tapped hazard report marker based strictly on report metadata.
  static Future<AiExplanationResponse> explainHazard({
    required HazardReport hazard,
    required double distanceMeters,
  }) async {
    final hasNote = hazard.description != null && hazard.description!.trim().isNotEmpty;
    if (!AiConfig.aiInsightsEnabled) {
      return AiExplanationResponse.fallback(
        score: 100,
        deterministicBullets: [
          '${hazard.displayLabel} reported ${distanceMeters.round()} m away.',
          hasNote
              ? 'Community note: "${hazard.description}"'
              : 'No extra description provided by reporter.',
        ],
      );
    }

    try {
      final payload = {
        'hazard_type': hazard.displayLabel,
        'distance_m': distanceMeters.round(),
        'description': hazard.description ?? '',
        'confidence': hazard.confidence,
      };

      final response = await http
          .post(
            Uri.parse('${AiConfig.backendUrl}/api/explain-hazard'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(AiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['error'] != true) {
          return AiExplanationResponse.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('[AiExplanationService] Hazard explanation failed ($e).');
    }

    return AiExplanationResponse.fallback(
      score: 100,
      deterministicBullets: [
        '${hazard.displayLabel} reported ${distanceMeters.round()} m away.',
        if (hasNote) 'Note: ${hazard.description}',
      ],
    );
  }

  /// Answer user navigation question using supplied navigation context.
  static Future<AiExplanationResponse> answerQuestion({
    required String question,
    required Map<String, dynamic> navigationState,
  }) async {
    if (!AiConfig.aiInsightsEnabled) {
      return AiExplanationResponse.fallback(
        score: navigationState['safety_score'] ?? 100,
        deterministicBullets: [
          'AI assistance is currently operating in offline deterministic mode.',
          'Current safety score: ${navigationState['safety_score'] ?? 100}/100.',
        ],
      );
    }

    try {
      final payload = {
        'question': question,
        'navigation_state': navigationState,
      };

      final response = await http
          .post(
            Uri.parse('${AiConfig.backendUrl}/api/answer-question'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(AiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['error'] != true) {
          return AiExplanationResponse.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('[AiExplanationService] Question answering failed ($e).');
    }

    return AiExplanationResponse.fallback(
      score: navigationState['safety_score'] ?? 100,
      deterministicBullets: [
        'Response generated from local navigation state.',
        'Current distance remaining: ${navigationState['remaining_distance'] ?? 'N/A'}.',
      ],
    );
  }

  /// Generate AI trip insight summary upon destination arrival.
  static Future<AiExplanationResponse> generateTripInsight({
    required TripSummary tripSummary,
  }) async {
    if (!AiConfig.aiInsightsEnabled) {
      return AiExplanationResponse.fallback(
        score: tripSummary.finalSafetyScore,
        deterministicBullets: [
          'Completed trip: ${tripSummary.formattedDistance}, ${tripSummary.formattedDuration}.',
          'Encountered ${tripSummary.hazardSignalsCount} nearby safety signals.',
        ],
      );
    }

    try {
      final payload = {
        'trip_summary': tripSummary.toJson(),
      };

      final response = await http
          .post(
            Uri.parse('${AiConfig.backendUrl}/api/trip-insight'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(AiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['error'] != true) {
          return AiExplanationResponse.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('[AiExplanationService] Trip insight failed ($e).');
    }

    return AiExplanationResponse.fallback(
      score: tripSummary.finalSafetyScore,
      deterministicBullets: [
        'Completed trip: ${tripSummary.formattedDistance}, ${tripSummary.formattedDuration}.',
        'Encountered ${tripSummary.hazardSignalsCount} safety signals along the route.',
      ],
    );
  }

  /// Clear explanation cache.
  static void clearCache() => _cache.clear();
}
