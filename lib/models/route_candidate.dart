import 'route_model.dart';
import 'safety_score.dart';
import 'safety_signal.dart';

/// Container for a candidate walking route with attached safety scoring.
class RouteCandidate {
  final String id;
  final String title;
  final RouteModel route;
  final SafetyScore safetyScore;
  final int hazardCount;
  final List<SafetySignal> riskSignals;
  final bool isRecommended;

  const RouteCandidate({
    required this.id,
    required this.title,
    required this.route,
    required this.safetyScore,
    required this.hazardCount,
    required this.riskSignals,
    this.isRecommended = false,
  });

  /// Formatted distance string from underlying route model.
  String get formattedDistance => route.formattedDistance;

  /// Formatted duration string from underlying route model.
  String get formattedDuration => route.formattedDuration;
}
