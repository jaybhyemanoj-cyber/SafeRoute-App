/// Represents an individual safety risk signal detected along or near a route.
class SafetySignal {
  final String hazardType;
  final String label;
  final double penalty;
  final String description;
  final double distanceMeters;
  final DateTime createdAt;
  final double confidence;

  const SafetySignal({
    required this.hazardType,
    required this.label,
    required this.penalty,
    required this.description,
    required this.distanceMeters,
    required this.createdAt,
    required this.confidence,
  });

  /// Readable summary string for UI bullet points.
  String get formattedSummary {
    final distStr = distanceMeters < 50
        ? 'along the path'
        : 'approx. ${distanceMeters.round()}m from route';
    return '$label ($distStr)';
  }
}
