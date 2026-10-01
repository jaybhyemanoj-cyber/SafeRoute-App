import 'package:flutter/material.dart';
import '../models/route_candidate.dart';
import '../models/ai_explanation_response.dart';
import '../services/ai_explanation_service.dart';
import '../theme/app_colors.dart';

/// Modal sheet explaining deterministic score rationales & candidate trade-offs.
class WhyThisRouteSheet extends StatefulWidget {
  final RouteCandidate selectedCandidate;
  final List<RouteCandidate> allCandidates;

  const WhyThisRouteSheet({
    super.key,
    required this.selectedCandidate,
    this.allCandidates = const [],
  });

  static Future<void> show(
    BuildContext context, {
    required RouteCandidate selectedCandidate,
    List<RouteCandidate> allCandidates = const [],
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WhyThisRouteSheet(
        selectedCandidate: selectedCandidate,
        allCandidates: allCandidates,
      ),
    );
  }

  @override
  State<WhyThisRouteSheet> createState() => _WhyThisRouteSheetState();
}

class _WhyThisRouteSheetState extends State<WhyThisRouteSheet> {
  late Future<AiExplanationResponse> _explanationFuture;

  @override
  void initState() {
    super.initState();
    _loadExplanation();
  }

  void _loadExplanation() {
    if (widget.allCandidates.length > 1) {
      _explanationFuture = AiExplanationService.explainRouteComparison(
        candidates: widget.allCandidates,
      );
    } else {
      _explanationFuture = AiExplanationService.explainRouteScore(
        safetyScore: widget.selectedCandidate.safetyScore,
        distanceMeters: widget.selectedCandidate.route.distanceMeters,
        durationSeconds: widget.selectedCandidate.route.durationSeconds,
        routeId: widget.selectedCandidate.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = widget.selectedCandidate.safetyScore;
    final badgeColor = widget.selectedCandidate.safetyScore.badgeColor;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.shield_outlined, color: AppColors.primary, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Why This Route?',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Safety Score Breakdown & Signal Analysis',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: badgeColor,
                    ),
                  ),
                  child: Text(
                    '${score.overallScore}/100',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            FutureBuilder<AiExplanationResponse>(
              future: _explanationFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }

                final ai = snapshot.data ??
                    AiExplanationResponse.fallback(
                      score: score.overallScore,
                      deterministicBullets: score.whyBulletPoints,
                    );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ai.summary,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'VERIFIED SAFETY FACTORS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...score.signals.map((sig) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                sig.penalty > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                                size: 18,
                                color: sig.penalty > 0 ? AppColors.warning : AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${sig.label}: ${sig.formattedSummary}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              if (sig.penalty > 0)
                                Text(
                                  '-${sig.penalty.toStringAsFixed(1)} pts',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.danger,
                                  ),
                                ),
                            ],
                          ),
                        )),
                    if (score.signals.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          '✓ No community hazards reported along this path.',
                          style: TextStyle(fontSize: 13, color: AppColors.primaryDark),
                        ),
                      ),
                    if (ai.tradeoffs.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'ROUTE TRADEOFFS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...ai.tradeoffs.map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• $t',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ai.disclaimer,
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Got it', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
