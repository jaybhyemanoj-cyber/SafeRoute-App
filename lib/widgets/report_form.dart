import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../models/hazard_report.dart';
import '../services/report_service.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'primary_button.dart';

/// Bottom sheet dialog for creating and submitting a new hazard report.
class ReportFormSheet extends StatefulWidget {
  final LatLng? currentLocation;
  final VoidCallback onReportSubmitted;

  const ReportFormSheet({
    super.key,
    required this.currentLocation,
    required this.onReportSubmitted,
  });

  @override
  State<ReportFormSheet> createState() => _ReportFormSheetState();
}

class _ReportFormSheetState extends State<ReportFormSheet> {
  String? _selectedCategory;
  final _descriptionController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not select photo. Please check permissions.';
      });
    }
  }

  Future<void> _submitReport() async {
    setState(() {
      _errorMessage = null;
    });

    if (_selectedCategory == null) {
      setState(() {
        _errorMessage = 'Please select a hazard category.';
      });
      return;
    }

    if (widget.currentLocation == null) {
      setState(() {
        _errorMessage =
            'We couldn\'t detect your location. Please enable location services and try again.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final reportId = DateTime.now().millisecondsSinceEpoch.toString();
      final userId = SupabaseService.instance.currentUserId;
      String? photoUrl;

      // 1. Upload photo if selected
      if (_imageFile != null) {
        photoUrl = await StorageService.uploadReportImage(
          imageFile: _imageFile!,
          reportId: reportId,
          userId: userId,
        );
      }

      // 2. Build report model
      final report = HazardReport(
        id: reportId,
        userId: userId,
        latitude: widget.currentLocation!.latitude,
        longitude: widget.currentLocation!.longitude,
        hazardType: _selectedCategory!,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        photoUrl: photoUrl,
        createdAt: DateTime.now(),
        status: 'active',
        confidence: 0.5,
      );

      // 3. Save to Supabase
      await ReportService.submitReport(report);

      if (!mounted) return;

      // 4. Success State & Close
      widget.onReportSubmitted();
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Report submitted! Thanks for helping make walking safer.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primaryDark,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg + bottomPadding,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
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
            const SizedBox(height: AppSpacing.md),

            // Header
            Text(
              'Report a Hazard',
              style: AppTypography.heading2,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Help other pedestrians stay informed.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),

            // Error banner if any
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.danger.withAlpha(25),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.danger.withAlpha(75)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.danger, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Location Indicator
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.my_location_rounded,
                    color: widget.currentLocation != null
                        ? AppColors.primary
                        : AppColors.danger,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          widget.currentLocation != null
                              ? 'Current GPS coordinates detected (${widget.currentLocation!.latitude.toStringAsFixed(4)}, ${widget.currentLocation!.longitude.toStringAsFixed(4)})'
                              : 'GPS unavailable. Enable location services.',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Select Hazard Type
            Text(
              'Select Hazard Category',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: HazardReport.hazardCategories.map((category) {
                final key = category['key'] as String;
                final label = category['label'] as String;
                final emoji = category['emoji'] as String;
                final isSelected = _selectedCategory == key;

                return ChoiceChip(
                  label: Text('$emoji $label'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected ? key : null;
                    });
                  },
                  selectedColor: AppColors.primaryContainer,
                  backgroundColor: AppColors.inputBackground,
                  labelStyle: AppTypography.caption.copyWith(
                    color: isSelected
                        ? AppColors.primaryDark
                        : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),

            // Description Field
            Text(
              'Description (Optional)',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _descriptionController,
              maxLength: 300,
              maxLines: 3,
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Tell us what pedestrians should know...',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
                filled: true,
                fillColor: AppColors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(AppSpacing.md),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Photo Upload
            Text(
              'Add Photo (Optional)',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            if (_imageFile == null) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded, size: 18),
                      label: const Text('Take Photo'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded, size: 18),
                      label: const Text('Choose Gallery'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: Image.file(
                      _imageFile!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _imageFile = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0x99000000),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),

            // Submit Button
            PrimaryButton(
              text: _isSubmitting ? 'Submitting report...' : 'Submit Report',
              onPressed: _isSubmitting ? null : _submitReport,
              isLoading: _isSubmitting,
            ),
          ],
        ),
      ),
    );
  }
}
