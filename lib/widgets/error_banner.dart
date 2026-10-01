import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class ErrorBanner {
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    IconData icon = Icons.info_outline_rounded,
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.all(AppSpacing.lg),
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.textPrimary,
            borderRadius: AppSpacing.roundedLg,
            boxShadow: AppColors.floatingShadow,
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryLight, size: 24),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.headingSmall.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (onRetry != null)
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    onRetry();
                  },
                  child: Text(
                    'Retry',
                    style: AppTypography.buttonText.copyWith(
                      fontSize: 14,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
