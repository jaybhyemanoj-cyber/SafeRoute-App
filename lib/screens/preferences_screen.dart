import 'package:flutter/material.dart';
import '../models/user_preferences.dart';
import '../services/auth_service.dart';
import '../services/preferences_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/primary_button.dart';

/// Settings & Safety Preferences Screen (Phase 6).
class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final _authService = AuthService();
  bool _isLoading = true;
  bool _isSaving = false;
  late UserPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final user = _authService.currentUser;
    if (user != null) {
      final loaded = await PreferencesService.getPreferences(user.uid);
      if (mounted) {
        setState(() {
          _prefs = loaded;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _prefs = UserPreferences.defaultPreferences('');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _savePreferences() async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final saved = await PreferencesService.updatePreferences(_prefs);
      if (mounted) {
        setState(() {
          _prefs = saved;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Safety preferences saved successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Safety Preferences', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
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
                  // Section 1: Route Preference Mode
                  _buildSectionHeader('ROUTE PREFERENCE MODE', Icons.alt_route_rounded),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Choose how candidate routes are ranked for walking guidance.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      _buildModeChip('Balanced', 'balanced', Icons.balance_rounded),
                      const SizedBox(width: 8),
                      _buildModeChip('Safety Priority', 'safety_priority', Icons.shield_rounded),
                      const SizedBox(width: 8),
                      _buildModeChip('Time Priority', 'time_priority', Icons.speed_rounded),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Section 2: Hazard Avoidance Toggles
                  _buildSectionHeader('HAZARD AVOIDANCE PREFERENCES', Icons.warning_amber_rounded),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Routes will heavily penalize and bypass hazards you choose to avoid.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          'Heavy Traffic',
                          'Avoid busy vehicle roadways',
                          _prefs.avoidHeavyTraffic,
                          (v) => setState(() => _prefs = _prefs.copyWith(avoidHeavyTraffic: v)),
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          'Broken Footpaths',
                          'Avoid damaged or missing sidewalks',
                          _prefs.avoidBrokenFootpaths,
                          (v) => setState(() => _prefs = _prefs.copyWith(avoidBrokenFootpaths: v)),
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          'Construction Zones',
                          'Avoid active roadwork',
                          _prefs.avoidConstruction,
                          (v) => setState(() => _prefs = _prefs.copyWith(avoidConstruction: v)),
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          'Waterlogging',
                          'Avoid flooded path segments',
                          _prefs.avoidWaterlogging,
                          (v) => setState(() => _prefs = _prefs.copyWith(avoidWaterlogging: v)),
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          'Unsafe Crossings',
                          'Avoid unlit/high-risk intersections',
                          _prefs.avoidUnsafeCrossings,
                          (v) => setState(() => _prefs = _prefs.copyWith(avoidUnsafeCrossings: v)),
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          'Road Damage',
                          'Avoid potholes & unpaved terrain',
                          _prefs.avoidRoadDamage,
                          (v) => setState(() => _prefs = _prefs.copyWith(avoidRoadDamage: v)),
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          'Suspicious Activity',
                          'Avoid reported caution zones',
                          _prefs.avoidSuspiciousActivity,
                          (v) => setState(() => _prefs = _prefs.copyWith(avoidSuspiciousActivity: v)),
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          'Stray Animals',
                          'Avoid aggressive animal reports',
                          _prefs.avoidStrayAnimals,
                          (v) => setState(() => _prefs = _prefs.copyWith(avoidStrayAnimals: v)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Section 3: Alert Sensitivity
                  _buildSectionHeader('LIVE ALERT SENSITIVITY', Icons.notifications_active_rounded),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Controls how close to a hazard warning banner triggers during navigation.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      _buildSensitivityChip('Low (100m)', 'low'),
                      const SizedBox(width: 8),
                      _buildSensitivityChip('Medium (150m)', 'medium'),
                      const SizedBox(width: 8),
                      _buildSensitivityChip('High (200m)', 'high'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Section 4: AI Insights Toggle
                  _buildSectionHeader('AI SAFETY INSIGHTS', Icons.auto_awesome),
                  const SizedBox(height: AppSpacing.sm),
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
                        SwitchListTile(
                          title: const Text('Enable AI Insights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: const Text('Generates natural language route summaries using verified signals.', style: TextStyle(fontSize: 12)),
                          value: _prefs.aiInsightsEnabled,
                          activeColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (v) => setState(() => _prefs = _prefs.copyWith(aiInsightsEnabled: v)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'AI insights explain verified signals and route trade-offs. Numerical safety scores remain 100% deterministic.',
                          style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Save Action Button
                  PrimaryButton(
                    text: _isSaving ? 'Saving...' : 'Save Preferences',
                    icon: Icons.save_rounded,
                    onPressed: _isSaving ? () {} : _savePreferences,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildModeChip(String label, String value, IconData icon) {
    final isSelected = _prefs.routePreferenceMode == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _prefs = _prefs.copyWith(routePreferenceMode: value)),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryContainer : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isSelected ? AppColors.primaryDark : Colors.grey),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSensitivityChip(String label, String value) {
    final isSelected = _prefs.alertSensitivity == value;
    return Expanded(
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        selectedColor: AppColors.primaryContainer,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (_) => setState(() => _prefs = _prefs.copyWith(alertSensitivity: value)),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      value: value,
      activeColor: AppColors.primary,
      dense: true,
      onChanged: onChanged,
    );
  }
}
