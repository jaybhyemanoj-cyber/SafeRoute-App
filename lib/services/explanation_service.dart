import '../models/safety_score.dart';
import 'ai_explanation_service.dart';

/// Explanation Service providing deterministic and optional AI-assisted score rationales.
class ExplanationService {
  /// Generate concise natural language summary bullets for safety score.
  /// Delegates to secure AiExplanationService proxy backend with fallback.
  static Future<List<String>> getScoreExplanation({
    required SafetyScore safetyScore,
    required double distanceMeters,
    required double durationSeconds,
    String? geminiApiKey,
  }) async {
    final aiRes = await AiExplanationService.explainRouteScore(
      safetyScore: safetyScore,
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      routeId: 'route_${safetyScore.overallScore}',
    );

    if (aiRes.keyPoints.isNotEmpty) {
      return aiRes.keyPoints;
    }

    return safetyScore.whyBulletPoints;
  }
}
