import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/user_preferences.dart';

/// Production Hybrid Authentication Service using Firebase Auth + Supabase DB.
class AuthService {
  fb.FirebaseAuth get _fbAuth => fb.FirebaseAuth.instance;
  SupabaseClient get _client => Supabase.instance.client;

  /// Currently authenticated Firebase user.
  fb.User? get currentUser => _fbAuth.currentUser;

  /// User ID of authenticated user.
  String? get currentUserId => currentUser?.uid;

  /// Stream of authentication state changes.
  Stream<fb.User?> get authStateChanges => _fbAuth.authStateChanges();

  /// Check if user is logged in.
  bool get isAuthenticated => currentUser != null;

  /// Check if user email is verified.
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  /// Send email verification to current user.
  Future<void> sendEmailVerification() async {
    final user = currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Reload current user from Firebase Auth to get authoritative state.
  Future<fb.User?> reloadUser() async {
    final user = currentUser;
    if (user != null) {
      await user.reload();
      return _fbAuth.currentUser;
    }
    return null;
  }

  /// Sign Up with Email & Password using Firebase Auth.
  Future<fb.UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _fbAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (credential.user != null) {
      await credential.user!.updateDisplayName(displayName.trim());
      await credential.user!.sendEmailVerification();
      await _ensureUserProfileAndPreferences(
        userId: credential.user!.uid,
        displayName: displayName.trim(),
      );
    }

    return credential;
  }

  /// Log In with Email & Password using Firebase Auth.
  Future<fb.UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _fbAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (credential.user != null) {
      await credential.user!.reload();
      final name = credential.user!.displayName ?? email.split('@').first;
      await _ensureUserProfileAndPreferences(
        userId: credential.user!.uid,
        displayName: name,
      );
    }

    return credential;
  }

  /// Continue with 1-Tap Google Sign-In using Firebase Auth.
  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return false; // User cancelled

      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _fbAuth.signInWithCredential(credential);
      if (userCredential.user != null) {
        final name = userCredential.user!.displayName ?? googleUser.displayName ?? googleUser.email.split('@').first;
        await _ensureUserProfileAndPreferences(
          userId: userCredential.user!.uid,
          displayName: name,
        );
      }
      return true;
    } catch (e) {
      debugPrint('[AuthService] Firebase Google Sign-In Error: $e');
      rethrow;
    }
  }

  /// Send Password Reset Email.
  Future<void> sendPasswordResetEmail(String email) async {
    await _fbAuth.sendPasswordResetEmail(email: email.trim());
  }

  /// Sign Out.
  Future<void> signOut() async {
    await _fbAuth.signOut();
  }

  /// Helper to ensure profile and preferences records exist in Supabase DB.
  Future<void> _ensureUserProfileAndPreferences({
    required String userId,
    required String displayName,
  }) async {
    try {
      final profileRes = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (profileRes == null) {
        final profile = UserProfile(
          id: userId,
          displayName: displayName,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _client.from('profiles').insert(profile.toJson());
      }

      final prefRes = await _client
          .from('user_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (prefRes == null) {
        final prefs = UserPreferences.defaultPreferences(userId);
        await _client.from('user_preferences').insert(prefs.toJson());
      }
    } catch (e) {
      debugPrint('[AuthService] Non-critical Supabase sync warning: $e');
    }
  }
}
