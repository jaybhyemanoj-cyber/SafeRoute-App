import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import 'supabase_service.dart';

/// Service managing public.profiles table (Phase 6).
class ProfileService {
  static SupabaseClient? get _client => SupabaseService.instance.client;

  /// Fetch user profile by ID.
  static Future<UserProfile?> getProfile(String userId) async {
    if (_client == null) return null;
    try {
      final res = await _client!
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (res != null) {
        return UserProfile.fromJson(res);
      }
    } catch (e) {
      debugPrint('[ProfileService] Error fetching profile: $e');
    }
    return null;
  }

  /// Update display name for current user profile.
  static Future<UserProfile?> updateProfile({
    required String userId,
    required String displayName,
  }) async {
    if (_client == null) throw Exception('Supabase client not initialized');
    try {
      final now = DateTime.now().toIso8601String();
      final res = await _client!
          .from('profiles')
          .update({
            'display_name': displayName.trim(),
            'updated_at': now,
          })
          .eq('id', userId)
          .select()
          .single();

      return UserProfile.fromJson(res);
    } catch (e) {
      debugPrint('[ProfileService] Error updating profile: $e');
      rethrow;
    }
  }
}
