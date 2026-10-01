import 'package:flutter/material.dart';
import '../models/safety_insights_summary.dart';
import '../services/auth_service.dart';
import '../services/safety_insights_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// User Safety Insights & History Analytics Dashboard (Phase 6).
class SafetyInsightsScreen extends StatefulWidget {
  const SafetyInsightsScreen({super.key});

  @override
  State<SafetyInsightsScreen> createState() => _SafetyInsightsScreenState();
}

class _SafetyInsightsScreenState extends State<SafetyInsightsScreen> {
  final _authService = AuthService();
  bool _isLoading = true;
  late SafetyInsightsSummary _insights;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    final user = _authService.currentUser;
    if (user != null) {
      final summary = await SafetyInsightsService.getInsights(user.uid);
      if (mounted) {
        setState(() {
          _insights = summary;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _insights = SafetyInsightsSummary.empty();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmDeleteAccountData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Personal Data?'),
        content: const Text(
          'This will permanently remove your profile, safety preferences, and private route history from SafeRoute AI. Shared community hazard reports will remain anonymous.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete Data', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await SafetyInsightsService.deleteUserAccountData();
        await _authService.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account data deleted successfully.')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deletion failed: $e'), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Safety Insights', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Stats Header Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryDark, AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.insights_rounded, color: Colors.white, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Personal Route Analytics',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildHeaderStat('Total Trips', '${_insights.totalTrips}'),
                            _buildHeaderStat('Distance', _insights.formattedTotalDistance),
                            _buildHeaderStat('Avg Score', '${_insights.averageSafetyScore.round()}/100'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  if (!_insights.hasEnoughData) ...[
                    // Empty History State Banner
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'Not enough route history yet',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Keep using SafeRoute AI for walking navigation to build your personal safety insights.',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Frequently Encountered Hazards Section
                    const Text(
                      'FREQUENT HAZARDS ENCOUNTERED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: _insights.frequentlyEncounteredHazards.entries
                            .map(
                              (e) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        e.key.replaceAll('_', ' ').toUpperCase(),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Text(
                                      '${e.value} times',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),

                  // Privacy & Account Data Control
                  const Text(
                    'PRIVACY & DATA OWNERSHIP',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your personal preferences, profile, and route logs belong to you.',
                          style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _confirmDeleteAccountData,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: AppColors.danger),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.delete_forever_rounded, size: 18),
                          label: const Text('Delete My Personal Account Data', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
        ),
      ],
    );
  }
}
