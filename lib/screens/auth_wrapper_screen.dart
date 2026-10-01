import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// Application entry point routing based on Firebase Authentication state.
class AuthWrapperScreen extends StatelessWidget {
  const AuthWrapperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<fb.User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data ?? authService.currentUser;

        if (user != null) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
