import 'package:flutter/material.dart';
import '../services/emergency_service.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'emergency_contact_dialog.dart';


/// Private Emergency Status Card/Sheet displayed after activation.
class EmergencyStatusSheet extends StatelessWidget {
  const EmergencyStatusSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final emergencyService = EmergencyService.instance;

    return ListenableBuilder(
      listenable: emergencyService,
      builder: (context, _) {
        final status = emergencyService.status;
        final contact = emergencyService.currentContact;
        final smsStatusText = emergencyService.smsSendStatusText;
        final locationStatusText = emergencyService.locationStatusText;

        final isSending = status == EmergencyStatus.sendingSms || status == EmergencyStatus.locationPending;
        final isSent = status == EmergencyStatus.smsSent || status == EmergencyStatus.smsDelivered;
        final isFailed = status == EmergencyStatus.smsFailed;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('🚨', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergency Alert',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Alert activated',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    onPressed: () => emergencyService.stopEmergencySession(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.md),

              // SMS Status Row
              _buildStatusRow(
                icon: Icons.sms_rounded,
                title: 'SMS Status:',
                value: smsStatusText.isNotEmpty ? smsStatusText : 'Pending...',
                valueColor: isSent
                    ? AppColors.primaryDark
                    : isFailed
                        ? AppColors.danger
                        : AppColors.textPrimary,
                isSpinning: isSending,
              ),

              const SizedBox(height: AppSpacing.md),

              // Location Status Row
              _buildStatusRow(
                icon: Icons.location_on_rounded,
                title: 'Location:',
                value: locationStatusText.isNotEmpty ? locationStatusText : 'Locating...',
                valueColor: locationStatusText.contains('Shared')
                    ? AppColors.primaryDark
                    : Colors.grey.shade700,
              ),

              const SizedBox(height: AppSpacing.md),

              // Emergency Contact Row (Masked Phone Number)
              if (contact != null) ...[
                _buildStatusRow(
                  icon: Icons.person_pin_rounded,
                  title: contact.relationship.isNotEmpty ? contact.relationship : 'Parent',
                  value: '${contact.name} (${contact.maskedPhoneNumber})',
                  valueColor: AppColors.textPrimary,
                ),
                const SizedBox(height: AppSpacing.md),
              ] else if (isFailed) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const EmergencyContactDialog(),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    icon: const Icon(Icons.add_ic_call_rounded),
                    label: const Text('Configure Primary Emergency Contact'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              const SizedBox(height: AppSpacing.lg),


              // Stop Emergency Session Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => emergencyService.stopEmergencySession(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.stop_circle_rounded, color: Colors.white),
                  label: const Text(
                    'Stop Emergency Session',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String title,
    required String value,
    required Color valueColor,
    bool isSpinning = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isSpinning) ...[
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: valueColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
