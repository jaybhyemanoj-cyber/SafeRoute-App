import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'verify_email_screen.dart';

/// Application entry point routing based on Firebase Authentication state and email verification.
class AuthWrapperScreen extends StatefulWidget {
  const AuthWrapperScreen({super.key});

  @override
  State<AuthWrapperScreen> createState() => _AuthWrapperScreenState();
}

class _AuthWrapperScreenState extends State<AuthWrapperScreen> {
  final _authService = AuthService();
  bool _isCheckingVerification = true;

  @override
  void initState() {
    super.initState();
    _checkInitialUserVerification();
  }

  Future<void> _checkInitialUserVerification() async {
    final user = _authService.currentUser;
    if (user != null && !user.emailVerified) {
      try {
        await user.reload();
      } catch (e) {
        debugPrint('[AuthWrapper] Initial user reload warning: $e');
      }
    }
    if (mounted) {
      setState(() {
        _isCheckingVerification = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<fb.User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || _isCheckingVerification) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data ?? _authService.currentUser;

        if (user == null) {
          return const LoginScreen();
        }

        // Authoritative Firebase verification check
        if (user.emailVerified) {
          return const HomeScreen();
        }

        // Unverified email/password user -> Block main app & show verification screen
        return const VerifyEmailScreen();
      },
    );
  }
}
