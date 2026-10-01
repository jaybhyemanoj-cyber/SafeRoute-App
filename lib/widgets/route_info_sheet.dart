import 'package:flutter/material.dart';
import '../models/destination.dart';
import '../models/route_candidate.dart';
import '../models/route_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'primary_button.dart';
import 'route_stats.dart';
import 'safety_score_badge.dart';
import 'why_this_route_sheet.dart';

class RouteInfoSheet extends StatelessWidget {
  final Destination destination;
  final RouteModel route;
  final RouteCandidate? activeCandidate;
  final List<RouteCandidate> allCandidates;
  final VoidCallback onStartNavigation;
  final VoidCallback onClose;
  final VoidCallback? onShowSafetyBreakdown;

  const RouteInfoSheet({
    super.key,
    required this.destination,
    required this.route,
    this.activeCandidate,
    this.allCandidates = const [],
    required this.onStartNavigation,
    required this.onClose,
    this.onShowSafetyBreakdown,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.roundedSheet,
        boxShadow: AppColors.floatingShadow,
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header with Title & Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          activeCandidate?.title ?? 'Walking Route',
                          style: AppTypography.headingLarge,
                        ),
                        if (activeCandidate != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          SafetyScoreBadge(
                            safetyScore: activeCandidate!.safetyScore,
                            onTap: onShowSafetyBreakdown ??
                                () {
                                  WhyThisRouteSheet.show(
                                    context,
                                    selectedCandidate: activeCandidate!,
                                    allCandidates: allCandidates,
                                  );
                                },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      destination.title,
                      style: AppTypography.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                color: AppColors.textSecondary,
                onPressed: onClose,
                splashRadius: 20,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Statistics Blocks & "Why this route?" trigger
          RouteStats(
            formattedDistance: route.formattedDistance,
            formattedDuration: route.formattedDuration,
          ),

          if (activeCandidate != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  WhyThisRouteSheet.show(
                    context,
                    selectedCandidate: activeCandidate!,
                    allCandidates: allCandidates,
                  );
                },
                icon: const Icon(Icons.help_outline_rounded, size: 16, color: AppColors.primary),
                label: const Text(
                  'Why this route?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          // Start Navigation CTA Button
          PrimaryButton(
            text: 'Start Navigation',
            icon: Icons.navigation_rounded,
            onPressed: onStartNavigation,
          ),
        ],
      ),
    );
  }
}
