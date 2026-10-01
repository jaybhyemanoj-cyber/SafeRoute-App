import '../config/ai_config.dart';

/// Structured response model for AI safety insights.
class AiExplanationResponse {
  final String summary;
  final List<String> keyPoints;
  final List<String> tradeoffs;
  final String confidenceNote;
  final String disclaimer;
  final bool isFallback;
  final String? providerUsed;

  const AiExplanationResponse({
    required this.summary,
    required this.keyPoints,
    required this.tradeoffs,
    required this.confidenceNote,
    required this.disclaimer,
    this.isFallback = false,
    this.providerUsed,
  });

  factory AiExplanationResponse.fromJson(Map<String, dynamic> json) {
    return AiExplanationResponse(
      summary: json['summary'] as String? ?? 'Safety explanation based on available route signals.',
      keyPoints: (json['key_points'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      tradeoffs: (json['tradeoffs'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      confidenceNote: json['confidence_note'] as String? ??
          'Based on community reports currently available.',
      disclaimer: json['disclaimer'] as String? ?? AiConfig.disclaimerText,
      isFallback: json['is_fallback'] as bool? ?? false,
      providerUsed: json['provider_used'] as String?,
    );
  }

  /// Create a local deterministic fallback explanation when AI is offline or disabled.
  factory AiExplanationResponse.fallback({
    required int score,
    required List<String> deterministicBullets,
    String? customSummary,
  }) {
    return AiExplanationResponse(
      summary: customSummary ??
          'Deterministic safety analysis based on available community hazard reports (Score: $score/100).',
      keyPoints: deterministicBullets,
      tradeoffs: const ['Trade-offs calculated using route length and penalty scores.'],
      confidenceNote: 'Data derived from local deterministic safety engine.',
      disclaimer: AiConfig.disclaimerText,
      isFallback: true,
      providerUsed: 'Local Safety Engine',
    );
  }

  Map<String, dynamic> toJson() => {
        'summary': summary,
        'key_points': keyPoints,
        'tradeoffs': tradeoffs,
        'confidence_note': confidenceNote,
        'disclaimer': disclaimer,
        'is_fallback': isFallback,
        'provider_used': providerUsed,
      };
}
