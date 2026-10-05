import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/emergency_contact.dart';
import 'supabase_service.dart';

/// Production Emergency Contact Service linking Firebase Auth UID with Supabase DB & Offline Cache.
class EmergencyContactService {
  static String _localPrefsKey(String userId) => 'saferoute_emergency_contact_$userId';

  /// Get the current authenticated Firebase User ID.
  static String? get currentFirebaseUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Retrieve primary emergency contact (offline-first from SharedPreferences, fallback to Supabase DB)
  static Future<EmergencyContact?> getPrimaryContact([String? userId]) async {
    final targetUserId = userId ?? currentFirebaseUserId;
    if (targetUserId == null || targetUserId.isEmpty) return null;

    // 1. Check local storage first (for offline SOS availability)
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJsonStr = prefs.getString(_localPrefsKey(targetUserId));
      if (localJsonStr != null && localJsonStr.isNotEmpty) {
        final map = jsonDecode(localJsonStr);
        final contact = EmergencyContact.fromJson(map);
        if (contact.isValidPhoneNumber) {
          return contact;
        }
      }
    } catch (e) {
      debugPrint('[EmergencyContactService] Error reading local contact cache: $e');
    }

    // 2. Fetch from Supabase DB using Firebase UID as user_id
    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        final res = await client
            .from('emergency_contacts')
            .select()
            .eq('user_id', targetUserId)
            .maybeSingle();

        if (res != null) {
          final contact = EmergencyContact.fromJson(res);
          await saveLocally(contact, targetUserId);
          return contact;
        }
      } catch (e) {
        debugPrint('[EmergencyContactService] Error fetching emergency contact from Supabase: $e');
      }
    }

    return null;
  }

  /// Save primary emergency contact locally and sync with Supabase DB
  static Future<void> savePrimaryContact(EmergencyContact contact) async {
    final targetUserId = currentFirebaseUserId ?? contact.userId;
    if (targetUserId.isEmpty) {
      throw Exception('User must be authenticated with Firebase to save an emergency contact.');
    }

    final updatedContact = contact.copyWith(
      userId: targetUserId,
      updatedAt: DateTime.now(),
    );

    // 1. Save locally for instant offline persistence
    await saveLocally(updatedContact, targetUserId);

    // 2. Sync to Supabase DB
    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        final payload = {
          'user_id': targetUserId,
          'contact_name': updatedContact.contactName,
          'phone_number': updatedContact.phoneNumber,
          'relationship': updatedContact.relationship,
          'is_primary': true,
          'updated_at': DateTime.now().toIso8601String(),
        };

        // Check if existing record exists to preserve id
        final existing = await client
            .from('emergency_contacts')
            .select('id')
            .eq('user_id', targetUserId)
            .maybeSingle();

        if (existing != null && existing['id'] != null) {
          payload['id'] = existing['id'];
        }

        await client.from('emergency_contacts').upsert(payload);
      } catch (e) {
        debugPrint('[EmergencyContactService] Non-critical Supabase sync warning: $e');
      }
    }
  }

  /// Delete emergency contact from Supabase DB and local cache
  static Future<void> deletePrimaryContact([String? userId]) async {
    final targetUserId = userId ?? currentFirebaseUserId;
    if (targetUserId == null || targetUserId.isEmpty) return;

    // 1. Clear local cache
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_localPrefsKey(targetUserId));
    } catch (e) {
      debugPrint('[EmergencyContactService] Error clearing local cache: $e');
    }

    // 2. Delete from Supabase DB
    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('emergency_contacts').delete().eq('user_id', targetUserId);
      } catch (e) {
        debugPrint('[EmergencyContactService] Error deleting emergency contact from Supabase: $e');
      }
    }
  }

  /// Save contact JSON locally for offline usage
  static Future<void> saveLocally(EmergencyContact contact, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localPrefsKey(userId), jsonEncode(contact.toJson()));
    } catch (e) {
      debugPrint('[EmergencyContactService] Error saving locally: $e');
    }
  }
}
