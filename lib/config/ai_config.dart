import 'package:flutter/foundation.dart';

/// Centralized configuration for SafeRoute AI Explanation Layer (Phase 5).
class AiConfig {
  /// Global feature toggle for AI Insights.
  /// If set to false, application relies strictly on deterministic safety scoring.
  static bool aiInsightsEnabled = true;

  /// Backend server proxy URL.
  /// Uses 10.0.2.2 for Android emulator, localhost for desktop/tests, or environment variable.
  static String get backendUrl {
    const customUrl = String.fromEnvironment('AI_BACKEND_URL');
    if (customUrl.isNotEmpty) return customUrl;
    if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) {
      // 10.0.2.2 maps to host machine localhost from Android emulator
      // For physical Android devices on same Wi-Fi, host IP or local proxy can be used.
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  /// Network timeout duration for AI explanation requests.
  static const Duration timeout = Duration(seconds: 5);

  /// Standard user-facing AI safety disclaimer text.
  static const String disclaimerText =
      'AI insights are derived strictly from available community reports and geometry facts. Reports may be incomplete.';
}
