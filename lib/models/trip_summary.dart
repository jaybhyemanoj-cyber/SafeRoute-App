/// Trip summary data model recorded upon completing a walking navigation session (Phase 4 & Phase 5).
class TripSummary {
  final String destinationTitle;
  final double totalDistanceMeters;
  final double totalDurationSeconds;
  final String routeTitle;
  final int initialSafetyScore;
  final int finalSafetyScore;
  final int hazardSignalsCount;
  final int reroutesCount;
  final DateTime timestamp;

  const TripSummary({
    required this.destinationTitle,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
    required this.routeTitle,
    required this.initialSafetyScore,
    required this.finalSafetyScore,
    required this.hazardSignalsCount,
    required this.reroutesCount,
    required this.timestamp,
  });

  /// Formatted distance string e.g. "1.8 km" or "650 m"
  String get formattedDistance {
    if (totalDistanceMeters >= 1000) {
      return '${(totalDistanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${totalDistanceMeters.round()} m';
  }

  /// Formatted duration string e.g. "14 min"
  String get formattedDuration {
    final minutes = (totalDurationSeconds / 60).round();
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final rem = minutes % 60;
      return rem > 0 ? '$hours hr $rem min' : '$hours hr';
    }
    return '$minutes min';
  }

  Map<String, dynamic> toJson() => {
        'destination_title': destinationTitle,
        'total_distance_meters': totalDistanceMeters,
        'total_duration_seconds': totalDurationSeconds,
        'route_title': routeTitle,
        'initial_safety_score': initialSafetyScore,
        'final_safety_score': finalSafetyScore,
        'hazard_signals_count': hazardSignalsCount,
        'reroutes_count': reroutesCount,
        'timestamp': timestamp.toIso8601String(),
      };
}
