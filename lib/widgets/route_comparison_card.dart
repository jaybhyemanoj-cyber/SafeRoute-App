import 'package:flutter/material.dart';
import '../models/route_candidate.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'safety_score_badge.dart';

/// Card selector widget allowing users to compare and select route candidates.
class RouteComparisonSelector extends StatelessWidget {
  final List<RouteCandidate> candidates;
  final RouteCandidate selectedCandidate;
  final ValueChanged<RouteCandidate> onCandidateSelected;
  final ValueChanged<RouteCandidate> onShowBreakdown;

  const RouteComparisonSelector({
    super.key,
    required this.candidates,
    required this.selectedCandidate,
    required this.onCandidateSelected,
    required this.onShowBreakdown,
  });

  @override
  Widget build(BuildContext context) {
    if (candidates.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: candidates.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final cand = candidates[index];
          final isSelected = cand.id == selectedCandidate.id;

          return GestureDetector(
            onTap: () => onCandidateSelected(cand),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 170,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.surfaceElevated : AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 2.0 : 1.0,
                ),
                boxShadow: isSelected ? AppColors.floatingShadow : AppColors.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        cand.title,
                        style: AppTypography.headingSmall.copyWith(
                          fontSize: 13,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      SafetyScoreBadge(
                        safetyScore: cand.safetyScore,
                        isCompact: true,
                        onTap: () => onShowBreakdown(cand),
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      Text(
                        cand.formattedDistance,
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '• ${cand.formattedDuration}',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
