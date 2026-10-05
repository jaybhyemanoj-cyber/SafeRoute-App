import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'preferences_screen.dart';
import 'safety_insights_screen.dart';

import '../models/emergency_contact.dart';
import '../services/emergency_contact_service.dart';
import '../widgets/emergency_contact_dialog.dart';

/// User Profile Management Screen (Phase 6).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  bool _isLoading = true;
  UserProfile? _profile;
  EmergencyContact? _emergencyContact;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _authService.currentUser;
    if (user != null) {
      final p = await ProfileService.getProfile(user.uid);
      final c = await EmergencyContactService.getPrimaryContact(user.uid);
      if (mounted) {
        setState(() {
          _profile = p;
          _emergencyContact = c;
          _isLoading = false;
        });
      }
    } else {
      final c = await EmergencyContactService.getPrimaryContact();
      if (mounted) {
        setState(() {
          _emergencyContact = c;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _editEmergencyContact() async {
    final updated = await showDialog<EmergencyContact>(
      context: context,
      builder: (context) => EmergencyContactDialog(existingContact: _emergencyContact),
    );

    if (updated != null && mounted) {
      setState(() => _emergencyContact = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primary Emergency Contact saved!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _deleteEmergencyContact() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove emergency contact?'),
        content: const Text(
          'Emergency SOS will not be able to send an alert until a new emergency contact is added.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final user = _authService.currentUser;
      await EmergencyContactService.deletePrimaryContact(user?.uid);
      if (mounted) {
        setState(() => _emergencyContact = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency contact removed.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }


  Future<void> _editDisplayName() async {
    final controller = TextEditingController(text: _profile?.displayName ?? '');
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter new display name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && _authService.currentUser != null) {
      try {
        final updated = await ProfileService.updateProfile(
          userId: _authService.currentUserId!,
          displayName: newName,
        );
        if (mounted) {
          setState(() => _profile = updated);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Display name updated!'), backgroundColor: AppColors.primary),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating name: $e'), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Account & Profile', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
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
                children: [
                  const SizedBox(height: AppSpacing.md),
                  // User Avatar & Name
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primaryContainer,
                      child: Text(
                        (_profile?.displayName.isNotEmpty == true)
                            ? _profile!.displayName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _profile?.displayName ?? 'SafeRoute User',
                        style: AppTypography.headingMedium.copyWith(fontSize: 20),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                        onPressed: _editDisplayName,
                      ),
                    ],
                  ),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Menu Options Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.contact_phone_rounded, color: AppColors.danger),
                          title: const Text('Primary Emergency Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(
                            _emergencyContact != null
                                ? '${_emergencyContact!.name} (${_emergencyContact!.maskedPhoneNumber})'
                                : 'Tap to configure parent/emergency contact for SOS',
                            style: TextStyle(
                              fontSize: 12,
                              color: _emergencyContact != null ? AppColors.textPrimary : AppColors.danger,
                            ),
                          ),
                          trailing: _emergencyContact != null
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                                      onPressed: _editEmergencyContact,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger),
                                      onPressed: _deleteEmergencyContact,
                                    ),
                                  ],
                                )
                              : const Icon(Icons.chevron_right_rounded),
                          onTap: _editEmergencyContact,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.tune_rounded, color: AppColors.primary),
                          title: const Text('Safety Preferences', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: const Text('Customize hazard avoidance and alert sensitivity', style: TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const PreferencesScreen()),
                            );
                          },
                        ),

                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.insights_rounded, color: AppColors.primary),
                          title: const Text('Safety Insights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: const Text('View personal walking stats and hazard history', style: TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const SafetyInsightsScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Log Out CTA Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await _authService.signOut();
                        if (mounted) Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.danger),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
                      label: const Text('Log Out', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
