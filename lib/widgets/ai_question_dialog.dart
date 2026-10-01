import 'package:flutter/material.dart';
import '../models/ai_explanation_response.dart';
import '../services/ai_explanation_service.dart';
import '../theme/app_colors.dart';

/// Modal dialog allowing focused pedestrian navigation QA with AI.
class AiQuestionDialog extends StatefulWidget {
  final Map<String, dynamic> navigationState;

  const AiQuestionDialog({
    super.key,
    required this.navigationState,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> navigationState,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AiQuestionDialog(
        navigationState: navigationState,
      ),
    );
  }

  @override
  State<AiQuestionDialog> createState() => _AiQuestionDialogState();
}

class _AiQuestionDialogState extends State<AiQuestionDialog> {
  final TextEditingController _questionController = TextEditingController();
  bool _isLoading = false;
  AiExplanationResponse? _answer;

  final List<String> _suggestedQuestions = const [
    'What hazards are ahead?',
    'Why did my score change?',
    'Why is this route longer?',
    'What safety signals were considered?',
  ];

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _askQuestion(String question) async {
    if (question.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _questionController.text = question;
    });

    final res = await AiExplanationService.answerQuestion(
      question: question,
      navigationState: widget.navigationState,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _answer = res;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'Ask SafeRoute AI',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'SUGGESTED QUESTIONS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _suggestedQuestions
                  .map(
                    (q) => ChoiceChip(
                      label: Text(q, style: const TextStyle(fontSize: 12)),
                      selected: _questionController.text == q,
                      selectedColor: AppColors.primaryContainer,
                      backgroundColor: AppColors.inputBackground,
                      labelStyle: TextStyle(
                        color: _questionController.text == q
                            ? AppColors.primaryDark
                            : AppColors.textPrimary,
                        fontWeight: _questionController.text == q
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      onSelected: (_) => _askQuestion(q),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      hintText: 'Type your navigation question...',
                      hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    onSubmitted: _askQuestion,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isLoading ? null : () => _askQuestion(_questionController.text),
                  icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_answer != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _answer!.summary,
                      style: const TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
                    ),
                    if (_answer!.keyPoints.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ..._answer!.keyPoints.map(
                        (k) => Text('• $k', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _answer!.disclaimer,
                style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
