import 'package:flutter/material.dart';
import '../models/hazard_report.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Non-blocking dismissible contextual hazard warning alert banner (Phase 4).
class HazardAlertBanner extends StatelessWidget {
  final HazardReport report;
  final VoidCallback onDismiss;
  final VoidCallback onViewDetails;

  const HazardAlertBanner({
    super.key,
    required this.report,
    required this.onDismiss,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppColors.floatingShadow,
        border: Border.all(color: AppColors.warning, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs + 2),
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Safety signal nearby',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${report.displayLabel} reported ahead',
                  style: AppTypography.headingSmall.copyWith(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (report.description != null && report.description!.isNotEmpty)
                  Text(
                    report.description!,
                    style: AppTypography.caption.copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: onViewDetails,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              minimumSize: const Size(40, 32),
            ),
            child: Text(
              'View',
              style: AppTypography.button.copyWith(
                color: AppColors.primary,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
