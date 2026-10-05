import 'package:flutter/material.dart';
import '../models/emergency_contact.dart';
import '../services/auth_service.dart';
import '../services/emergency_contact_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Production Emergency Contact Form Dialog & First-Time Setup Sheet.
class EmergencyContactDialog extends StatefulWidget {
  final EmergencyContact? existingContact;
  final bool isFirstTimeSetup;

  const EmergencyContactDialog({
    super.key,
    this.existingContact,
    this.isFirstTimeSetup = false,
  });

  @override
  State<EmergencyContactDialog> createState() => _EmergencyContactDialogState();
}

class _EmergencyContactDialogState extends State<EmergencyContactDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  String _selectedRelationship = 'Parent';
  bool _isSaving = false;

  final List<String> _relationshipOptions = [
    'Parent',
    'Friend',
    'Spouse',
    'Sibling',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingContact?.contactName ?? '');
    _phoneController = TextEditingController(text: widget.existingContact?.phoneNumber ?? '');

    final existingRel = widget.existingContact?.relationship ?? 'Parent';
    if (_relationshipOptions.contains(existingRel)) {
      _selectedRelationship = existingRel;
    } else {
      _selectedRelationship = 'Other';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final userId = AuthService().currentUserId ?? '';
      if (userId.isEmpty) {
        throw Exception('User must be authenticated to save emergency contact.');
      }

      final contact = EmergencyContact(
        id: widget.existingContact?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        contactName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        relationship: _selectedRelationship,
        isPrimary: true,
      );

      await EmergencyContactService.savePrimaryContact(contact);

      if (mounted) {
        Navigator.of(context).pop(contact);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Emergency contact could not be saved. Please try again.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              widget.existingContact != null
                  ? 'Edit Emergency Contact'
                  : 'Add Emergency Contact',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add a trusted person who SafeRoute can contact when you trigger Emergency SOS.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.md),

              // Contact Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Contact Name',
                  hintText: 'e.g. Mom, Dad, Friend',
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter contact name';
                  if (val.trim().length > 50) return 'Name too long (max 50 characters)';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Phone Number
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+91 XXXXX XXXXX',
                  prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter phone number';
                  final digits = val.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 10) return 'Enter a valid phone number (min 10 digits)';
                  if (digits.length > 15) return 'Phone number too long';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Relationship Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedRelationship,
                decoration: InputDecoration(
                  labelText: 'Relationship',
                  prefixIcon: const Icon(Icons.people_outline_rounded, color: AppColors.textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _relationshipOptions.map((rel) {
                  return DropdownMenuItem<String>(
                    value: rel,
                    child: Text(rel),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRelationship = val);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(null),
          child: Text(
            widget.isFirstTimeSetup ? 'Add Later' : 'Cancel',
            style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveContact,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded, color: Colors.white, size: 18),
          label: Text(
            _isSaving ? 'Saving...' : 'Save Contact',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
