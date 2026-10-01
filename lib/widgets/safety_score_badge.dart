import 'package:flutter/material.dart';
import '../models/safety_score.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Compact badge widget displaying a route's safety score.
class SafetyScoreBadge extends StatelessWidget {
  final SafetyScore safetyScore;
  final VoidCallback? onTap;
  final bool isCompact;

  const SafetyScoreBadge({
    super.key,
    required this.safetyScore,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = safetyScore.badgeColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? AppSpacing.sm : AppSpacing.md,
            vertical: isCompact ? AppSpacing.xs : AppSpacing.xs + 2,
          ),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(
              color: color,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shield_rounded,
                color: color,
                size: isCompact ? 14 : 16,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${safetyScore.overallScore}/100',
                style: AppTypography.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: isCompact ? 11 : 13,
                ),
              ),
              if (!isCompact) ...[
                const SizedBox(width: AppSpacing.xs),
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.textMuted,
                  size: 14,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
