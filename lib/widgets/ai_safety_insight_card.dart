import 'package:flutter/material.dart';
import '../models/ai_explanation_response.dart';
import '../theme/app_colors.dart';

/// Card displaying AI-generated safety insights with clear disclaimers.
class AiSafetyInsightCard extends StatelessWidget {
  final AiExplanationResponse explanation;
  final VoidCallback? onAskQuestion;
  final VoidCallback? onWhyThisRoute;

  const AiSafetyInsightCard({
    super.key,
    required this.explanation,
    this.onAskQuestion,
    this.onWhyThisRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark.withOpacity(0.06),
            AppColors.primary.withOpacity(0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'AI Safety Insight',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                ),
              ),
              if (explanation.isFallback)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Offline / Local',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            explanation.summary,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textPrimary,
            ),
          ),
          if (explanation.keyPoints.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...explanation.keyPoints.map(
              (bullet) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        bullet,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (onWhyThisRoute != null)
                TextButton.icon(
                  onPressed: onWhyThisRoute,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.help_outline, size: 14, color: AppColors.primary),
                  label: const Text(
                    'Why this route?',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              const Spacer(),
              if (onAskQuestion != null)
                OutlinedButton.icon(
                  onPressed: onAskQuestion,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.primaryDark),
                  label: const Text(
                    'Ask AI',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                  ),
                ),
            ],
          ),
          const Divider(height: 16),
          Text(
            explanation.disclaimer,
            style: TextStyle(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
