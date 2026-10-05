
import 'safety_config.dart';

/// Centralized configuration for SafeRoute AI Explanation Layer (Phase 5).
class AiConfig {
  /// Global feature toggle for AI Insights.
  /// If set to false, application relies strictly on deterministic safety scoring.
  static bool aiInsightsEnabled = true;

  /// Backend server proxy URL.
  /// Points to live Render backend proxy or custom environment variable.
  static String get backendUrl {
    const customUrl = String.fromEnvironment('AI_BACKEND_URL');
    if (customUrl.isNotEmpty) return customUrl;
    return 'https://saferoute-app-z88y.onrender.com';
  }

  /// Network timeout duration for AI explanation requests.
  static const Duration timeout = Duration(seconds: 5);

  /// Standard user-facing AI safety disclaimer text.
  static const String disclaimerText = SafetyConfig.trustSystemDisclaimer;
}
