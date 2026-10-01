import 'package:flutter/material.dart';
import '../models/trip_summary.dart';
import '../models/ai_explanation_response.dart';
import '../services/ai_explanation_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'ai_safety_insight_card.dart';
import 'primary_button.dart';

/// Modal dialog / sheet presenting destination arrival & trip summary (Phase 4 & Phase 5).
class TripSummarySheet extends StatefulWidget {
  final TripSummary summary;
  final VoidCallback onFinish;

  const TripSummarySheet({
    super.key,
    required this.summary,
    required this.onFinish,
  });

  @override
  State<TripSummarySheet> createState() => _TripSummarySheetState();
}

class _TripSummarySheetState extends State<TripSummarySheet> {
  late Future<AiExplanationResponse> _tripInsightFuture;

  @override
  void initState() {
    super.initState();
    _tripInsightFuture = AiExplanationService.generateTripInsight(
      tripSummary: widget.summary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Arrival Badge Icon & Title
            Center(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 44,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Text(
                "You're here!",
                style: AppTypography.headingLarge.copyWith(color: AppColors.primaryDark),
              ),
            ),
            Center(
              child: Text(
                summary.destinationTitle,
                style: AppTypography.subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Trip Statistics Grid Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatTile(
                        label: 'Distance',
                        value: summary.formattedDistance,
                        icon: Icons.straighten_rounded,
                      ),
                      _buildStatTile(
                        label: 'Walking Time',
                        value: summary.formattedDuration,
                        icon: Icons.access_time_rounded,
                      ),
                      _buildStatTile(
                        label: 'Safety Score',
                        value: '${summary.finalSafetyScore}/100',
                        icon: Icons.shield_rounded,
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatTile(
                        label: 'Route Option',
                        value: summary.routeTitle,
                        icon: Icons.alt_route_rounded,
                      ),
                      _buildStatTile(
                        label: 'Hazards Near',
                        value: '${summary.hazardSignalsCount}',
                        icon: Icons.warning_amber_rounded,
                      ),
                      _buildStatTile(
                        label: 'Reroutes',
                        value: '${summary.reroutesCount}',
                        icon: Icons.sync_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // AI Trip Insight Card
            FutureBuilder<AiExplanationResponse>(
              future: _tripInsightFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  );
                }

                final aiRes = snapshot.data ??
                    AiExplanationResponse.fallback(
                      score: summary.finalSafetyScore,
                      deterministicBullets: [
                        'Completed trip: ${summary.formattedDistance}, ${summary.formattedDuration}.',
                        'Encountered ${summary.hazardSignalsCount} safety signals.',
                      ],
                    );

                return AiSafetyInsightCard(explanation: aiRes);
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Finish Action Button
            PrimaryButton(
              text: 'Finish',
              icon: Icons.done_rounded,
              onPressed: widget.onFinish,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.headingSmall.copyWith(fontSize: 14),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}
