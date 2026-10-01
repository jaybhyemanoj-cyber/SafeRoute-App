import 'package:flutter/material.dart';
import '../models/navigation_instruction.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Top turn-by-turn navigation maneuver card overlay (Phase 4).
class ManeuverCard extends StatelessWidget {
  final NavigationInstruction? instruction;
  final double distanceToNextManeuverMeters;
  final String destinationTitle;

  const ManeuverCard({
    super.key,
    required this.instruction,
    required this.distanceToNextManeuverMeters,
    required this.destinationTitle,
  });

  String get _formattedDistance {
    if (distanceToNextManeuverMeters >= 1000) {
      return 'in ${(distanceToNextManeuverMeters / 1000).toStringAsFixed(1)} km';
    }
    return 'in ${distanceToNextManeuverMeters.round()} m';
  }

  @override
  Widget build(BuildContext context) {
    if (instruction == null) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.roundedLg,
          boxShadow: AppColors.floatingShadow,
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.directions_walk_rounded, color: AppColors.primary, size: 24),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Walking to $destinationTitle',
                style: AppTypography.headingSmall.copyWith(fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.roundedLg,
        boxShadow: AppColors.floatingShadow,
        border: Border.all(color: AppColors.primary.withAlpha(80), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              instruction!.icon,
              color: AppColors.primaryDark,
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'NEXT',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '• $_formattedDistance',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  instruction!.formattedText,
                  style: AppTypography.headingSmall.copyWith(fontSize: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
