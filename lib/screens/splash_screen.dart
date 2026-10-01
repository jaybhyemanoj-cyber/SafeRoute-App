import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/constants.dart';
import 'auth_wrapper_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (context, animation, secondaryAnimation) => const AuthWrapperScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // SafeRoute AI Branded Logo
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(5, 150, 105, 0.35),
                    blurRadius: 28,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.route_rounded,
                    color: Colors.white24,
                    size: 56,
                  ),
                  const Icon(
                    Icons.location_on_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                  Positioned(
                    right: 22,
                    top: 22,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .scale(duration: 600.ms, curve: Curves.easeOutBack)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: AppSpacing.xxl),

            // App Title
            Text(
              AppConstants.appName,
              style: AppTypography.appTitle.copyWith(fontSize: 28),
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 500.ms)
                .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),

            const SizedBox(height: AppSpacing.xs),

            // Tagline
            Text(
              AppConstants.splashTagline,
              style: AppTypography.subtitle.copyWith(fontSize: 15),
            )
                .animate()
                .fadeIn(delay: 400.ms, duration: 500.ms)
                .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
          ],
        ),
      ),
    );
  }
}
