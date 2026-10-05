import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/primary_button.dart';
import 'auth_wrapper_screen.dart';

/// Mandatory Email Verification Screen for SafeRoute AI.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _authService = AuthService();
  bool _isChecking = false;
  bool _isResending = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldownSeconds = 45);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 1) {
        if (mounted) setState(() => _cooldownSeconds--);
      } else {
        timer.cancel();
        if (mounted) setState(() => _cooldownSeconds = 0);
      }
    });
  }

  String _maskEmail(String rawEmail) {
    if (!rawEmail.contains('@')) return rawEmail;
    final parts = rawEmail.split('@');
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 1) {
      return '$name***@$domain';
    }
    return '${name[0]}***@$domain';
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.primary,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _openEmailApp() async {
    try {
      final Uri emailLaunchUri = Uri(scheme: 'mailto');
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar(
          'No email application is available on this device. Please open your email through your browser.',
          isError: true,
        );
      }
    } catch (_) {
      _showSnackBar(
        'No email application is available on this device. Please open your email through your browser.',
        isError: true,
      );
    }
  }

  Future<void> _checkVerification() async {
    setState(() => _isChecking = true);
    try {
      final user = await _authService.reloadUser();
      if (user != null && user.emailVerified) {
        if (mounted) {
          _showSnackBar('Email verified successfully!', isError: false);
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthWrapperScreen()),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          _showSnackBar(
            'Email not verified yet. Please open the verification email and try again.',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'Error checking verification state. Please try again.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resendVerification() async {
    if (_cooldownSeconds > 0 || _isResending) return;
    setState(() => _isResending = true);
    try {
      await _authService.sendEmailVerification();
      if (mounted) {
        _showSnackBar('Verification email sent. Please check your inbox and spam folder.');
        _startCooldown();
      }
    } catch (e) {
      String msg = 'Unable to send verification email. Please try again.';
      if (e.toString().contains('too-many-requests')) {
        msg = 'Please wait a moment before requesting another verification email.';
      }
      if (mounted) _showSnackBar(msg, isError: true);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthWrapperScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final rawEmail = user?.email ?? '';
    final maskedEmail = _maskEmail(rawEmail);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_outlined,
                      color: AppColors.primary,
                      size: 56,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Heading
                Text(
                  'Verify your email',
                  style: AppTypography.headingLarge.copyWith(fontSize: 26),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),

                // Description
                Text(
                  'We\'ve sent a verification link to your email address:',
                  style: AppTypography.subtitle.copyWith(fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  maskedEmail.isNotEmpty ? maskedEmail : 'your email address',
                  style: AppTypography.headingMedium.copyWith(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Please verify your email before continuing to SafeRoute AI.',
                  style: AppTypography.subtitle.copyWith(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Button 1: Open Email App
                OutlinedButton.icon(
                  onPressed: _openEmailApp,
                  icon: const Icon(Icons.mail_outline_rounded, color: AppColors.primary),
                  label: const Text(
                    'Open Email App',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Button 2: I've Verified My Email
                PrimaryButton(
                  text: _isChecking ? 'Checking verification...' : 'I\'ve Verified My Email',
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: _isChecking ? () {} : _checkVerification,
                ),
                const SizedBox(height: AppSpacing.md),

                // Button 3: Resend Verification Email
                TextButton.icon(
                  onPressed: (_cooldownSeconds > 0 || _isResending) ? null : _resendVerification,
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: (_cooldownSeconds > 0 || _isResending)
                        ? AppColors.textSecondary
                        : AppColors.primary,
                  ),
                  label: Text(
                    _isResending
                        ? 'Sending...'
                        : _cooldownSeconds > 0
                            ? 'Resend in ${_cooldownSeconds}s'
                            : 'Resend Verification Email',
                    style: TextStyle(
                      color: (_cooldownSeconds > 0 || _isResending)
                          ? AppColors.textSecondary
                          : AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),

                // Button 4: Back to Login
                TextButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
                  label: const Text(
                    'Back to Login',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
