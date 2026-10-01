import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/ai_config.dart';
import '../models/user_preferences.dart';
import 'supabase_service.dart';

/// Service managing public.user_preferences table (Phase 6).
class PreferencesService {
  static SupabaseClient? get _client => SupabaseService.instance.client;

  /// Fetch user preferences by user ID (defaults to current authenticated user).
  static Future<UserPreferences> getPreferences([String? userId]) async {
    final targetUserId = userId ?? SupabaseService.instance.currentUserId ?? 'anonymous';
    if (_client == null || targetUserId == 'anonymous') {
      return UserPreferences.defaultPreferences(targetUserId);
    }
    try {
      final res = await _client!
          .from('user_preferences')
          .select()
          .eq('user_id', targetUserId)
          .maybeSingle();

      if (res != null) {
        final prefs = UserPreferences.fromJson(res);
        // Sync global AI feature toggle
        AiConfig.aiInsightsEnabled = prefs.aiInsightsEnabled;
        return prefs;
      }
    } catch (e) {
      debugPrint('[PreferencesService] Error fetching preferences: $e');
    }
    return UserPreferences.defaultPreferences(targetUserId);
  }

  /// Update user preferences.
  static Future<UserPreferences> updatePreferences(UserPreferences prefs) async {
    try {
      final now = DateTime.now().toIso8601String();
      final updatedData = prefs.toJson();
      updatedData['updated_at'] = now;

      if (_client == null) {
        throw Exception('Supabase client not initialized');
      }

      final res = await _client!
          .from('user_preferences')
          .upsert(updatedData)
          .select()
          .single();

      final updatedPrefs = UserPreferences.fromJson(res);
      // Sync global AI feature toggle
      AiConfig.aiInsightsEnabled = updatedPrefs.aiInsightsEnabled;
      return updatedPrefs;
    } catch (e) {
      debugPrint('[PreferencesService] Error saving preferences: $e');
      rethrow;
    }
  }
}
