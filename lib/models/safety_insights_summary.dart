/// Summary analytics compiled from the authenticated user's private route history (Phase 6).
class SafetyInsightsSummary {
  final int totalTrips;
  final double totalDistanceMeters;
  final double totalDurationSeconds;
  final double averageSafetyScore;
  final Map<String, int> frequentlyEncounteredHazards;
  final List<String> frequentRoutes;
  final bool hasEnoughData;

  const SafetyInsightsSummary({
    required this.totalTrips,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
    required this.averageSafetyScore,
    required this.frequentlyEncounteredHazards,
    required this.frequentRoutes,
    required this.hasEnoughData,
  });

  factory SafetyInsightsSummary.empty() {
    return const SafetyInsightsSummary(
      totalTrips: 0,
      totalDistanceMeters: 0.0,
      totalDurationSeconds: 0.0,
      averageSafetyScore: 100.0,
      frequentlyEncounteredHazards: {},
      frequentRoutes: [],
      hasEnoughData: false,
    );
  }

  String get formattedTotalDistance {
    if (totalDistanceMeters >= 1000) {
      return '${(totalDistanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${totalDistanceMeters.round()} m';
  }

  String get formattedTotalDuration {
    final minutes = (totalDurationSeconds / 60).round();
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final rem = minutes % 60;
      return rem > 0 ? '$hours hr $rem min' : '$hours hr';
    }
    return '$minutes min';
  }
}
