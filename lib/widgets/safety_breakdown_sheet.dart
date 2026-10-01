import 'package:flutter/material.dart';
import '../models/route_candidate.dart';
import '../models/safety_score.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Modal sheet explaining why a safety score was assigned to a route candidate.
class SafetyBreakdownSheet extends StatelessWidget {
  final SafetyScore safetyScore;
  final RouteCandidate? candidate;

  const SafetyBreakdownSheet({
    super.key,
    required this.safetyScore,
    this.candidate,
  });

  String get _densityLabel {
    final count = safetyScore.signals.length;
    if (count == 0) return 'Low';
    if (count <= 2) return 'Low';
    if (count <= 4) return 'Moderate';
    return 'High';
  }

  int get _recentReportsCount {
    final now = DateTime.now();
    return safetyScore.signals
        .where((s) => now.difference(s.createdAt).inHours <= 48)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final color = safetyScore.badgeColor;

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
            // Drag handle
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

            // Title & Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Safety Analysis',
                  style: AppTypography.heading2,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Score Banner
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: color.withAlpha(15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: color.withAlpha(50)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${safetyScore.overallScore}',
                        style: AppTypography.headingLarge.copyWith(
                          color: Colors.white,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          safetyScore.safetyLabel,
                          style: AppTypography.headingSmall.copyWith(color: color),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Evaluated from community reports & route signals',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Analysis Metrics Grid
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricTile(
                        label: 'Hazards nearby',
                        value: '${safetyScore.signals.length}',
                        icon: Icons.warning_amber_rounded,
                      ),
                      _buildMetricTile(
                        label: 'Recent reports',
                        value: '$_recentReportsCount',
                        icon: Icons.access_time_rounded,
                      ),
                      _buildMetricTile(
                        label: 'Hazard density',
                        value: _densityLabel,
                        icon: Icons.density_medium_rounded,
                      ),
                    ],
                  ),
                  if (candidate != null) ...[
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricTile(
                          label: 'Route length',
                          value: candidate!.formattedDistance,
                          icon: Icons.straighten_rounded,
                        ),
                        _buildMetricTile(
                          label: 'Estimated time',
                          value: candidate!.formattedDuration,
                          icon: Icons.directions_walk_rounded,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // "What influenced this score?" Section
            Text(
              'What influenced this score?',
              style: AppTypography.headingSmall.copyWith(fontSize: 15),
            ),
            const SizedBox(height: AppSpacing.sm),

            ...safetyScore.whyBulletPoints.map(
              (bullet) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs + 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Expanded(
                      child: Text(
                        bullet,
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Detected Signals List
            if (safetyScore.signals.isNotEmpty) ...[
              Text(
                'Detected Route Signals (${safetyScore.signals.length}):',
                style: AppTypography.headingSmall.copyWith(fontSize: 14),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...safetyScore.signals.map(
                (signal) => Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 18, color: AppColors.warning),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          signal.formattedSummary,
                          style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Disclaimer Banner
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.privacy_tip_outlined, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Safety score is based on available map and community-report data. Conditions can change. Use your judgment while walking.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
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
