import 'package:flutter/material.dart';
import '../models/hazard_report.dart';
import '../models/ai_explanation_response.dart';
import '../services/ai_explanation_service.dart';
import '../theme/app_colors.dart';

/// Modal sheet detailing a tapped hazard marker with factual AI guidance.
class HazardExplanationSheet extends StatefulWidget {
  final HazardReport hazard;
  final double distanceMeters;

  const HazardExplanationSheet({
    super.key,
    required this.hazard,
    required this.distanceMeters,
  });

  static Future<void> show(
    BuildContext context, {
    required HazardReport hazard,
    required double distanceMeters,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HazardExplanationSheet(
        hazard: hazard,
        distanceMeters: distanceMeters,
      ),
    );
  }

  @override
  State<HazardExplanationSheet> createState() => _HazardExplanationSheetState();
}

class _HazardExplanationSheetState extends State<HazardExplanationSheet> {
  late Future<AiExplanationResponse> _explanationFuture;

  @override
  void initState() {
    super.initState();
    _explanationFuture = AiExplanationService.explainHazard(
      hazard: widget.hazard,
      distanceMeters: widget.distanceMeters,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hazard = widget.hazard;
    final hasNote = hazard.description != null && hazard.description!.trim().isNotEmpty;

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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hazard.displayLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '~${widget.distanceMeters.round()} m from route',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          if (hasNote) ...[
            const Text(
              'COMMUNITY REPORTER NOTE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '"${hazard.description}"',
                style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 14),
          ],
          FutureBuilder<AiExplanationResponse>(
            future: _explanationFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }

              final ai = snapshot.data ??
                  AiExplanationResponse.fallback(
                    score: 100,
                    deterministicBullets: [
                      'Reported ${hazard.displayLabel} nearby.',
                      'Exercise normal pedestrian caution.',
                    ],
                  );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI GUIDANCE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ai.summary,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ai.disclaimer,
                    style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
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
              child: const Text('Dismiss', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
