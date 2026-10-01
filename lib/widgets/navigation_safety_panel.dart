import 'package:flutter/material.dart';
import '../models/hazard_report.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Expandable safety signals panel drawer during live navigation (Phase 4).
class NavigationSafetyPanel extends StatefulWidget {
  final List<HazardReport> nearbyReports;
  final ValueChanged<HazardReport>? onReportTap;

  const NavigationSafetyPanel({
    super.key,
    required this.nearbyReports,
    this.onReportTap,
  });

  @override
  State<NavigationSafetyPanel> createState() => _NavigationSafetyPanelState();
}

class _NavigationSafetyPanelState extends State<NavigationSafetyPanel> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final count = widget.nearbyReports.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppColors.softShadow,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    count == 0 ? Icons.shield_rounded : Icons.warning_amber_rounded,
                    size: 18,
                    color: count == 0 ? AppColors.primary : AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.xs + 2),
                  Expanded(
                    child: Text(
                      count == 0
                          ? 'SAFETY SIGNALS • Clear path detected'
                          : 'SAFETY SIGNALS • $count community reports nearby',
                      style: AppTypography.caption.copyWith(
                        color: count == 0 ? AppColors.primary : AppColors.warning,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Reports List
          if (_isExpanded) ...[
            const Divider(height: 1),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              child: count == 0
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        'No active community hazard reports detected in immediate area.',
                        style: AppTypography.caption,
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      itemCount: widget.nearbyReports.length,
                      itemBuilder: (context, index) {
                        final rep = widget.nearbyReports[index];
                        return ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: Text(rep.emoji, style: const TextStyle(fontSize: 16)),
                          title: Text(
                            rep.displayLabel,
                            style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                          ),
                          subtitle: Text(
                            rep.description ?? 'Reported hazard',
                            style: AppTypography.caption.copyWith(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => widget.onReportTap?.call(rep),
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
