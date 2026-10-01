import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Service managing Supabase initialization and anonymous sessions.
class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();

  SupabaseService._internal();

  bool _isInitialized = false;

  /// Check if Supabase SDK is successfully initialized.
  bool get isInitialized => _isInitialized;

  /// Get SupabaseClient instance if initialized.
  SupabaseClient? get client => _isInitialized ? Supabase.instance.client : null;

  /// Initialize Supabase client with project credentials.
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (!SupabaseConfig.isConfigured) {
      debugPrint('[SupabaseService] Supabase credentials not set. Running in unconfigured mode.');
      return;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        // ignore: deprecated_member_use
        anonKey: SupabaseConfig.anonKey,
      );
      _isInitialized = true;
      debugPrint('[SupabaseService] Initialized successfully.');

      // Ensure anonymous session is active if supported
      await _ensureAnonymousSession();
    } catch (e) {
      debugPrint('[SupabaseService] Initialization failed: $e');
      _isInitialized = false;
    }
  }

  /// Ensure an anonymous session exists for low-friction user reporting.
  Future<void> _ensureAnonymousSession() async {
    if (!_isInitialized || client == null) return;
    try {
      final currentSession = client!.auth.currentSession;
      if (currentSession == null) {
        debugPrint('[SupabaseService] Signing in anonymously...');
        await client!.auth.signInAnonymously();
      }
    } catch (e) {
      debugPrint('[SupabaseService] Anonymous sign-in warning: $e');
    }
  }

  /// Get current user ID (if signed in or anonymous session exists).
  String? get currentUserId {
    return client?.auth.currentUser?.id;
  }
}
