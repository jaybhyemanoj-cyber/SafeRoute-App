import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class RouteStats extends StatelessWidget {
  final String formattedDistance;
  final String formattedDuration;

  const RouteStats({
    super.key,
    required this.formattedDistance,
    required this.formattedDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Distance Block
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: AppSpacing.roundedSm,
                  ),
                  child: const Icon(
                    Icons.directions_walk_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedDistance,
                        style: AppTypography.headingMedium,
                      ),
                      Text(
                        'Distance',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),

        // Duration Block
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: AppSpacing.roundedSm,
                  ),
                  child: const Icon(
                    Icons.access_time_filled_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedDuration,
                        style: AppTypography.headingMedium,
                      ),
                      Text(
                        'Est. Walking Time',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
