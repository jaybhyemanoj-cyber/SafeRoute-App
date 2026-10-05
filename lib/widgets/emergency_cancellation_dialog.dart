import 'package:flutter/material.dart';
import '../services/emergency_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// 5-second silent cancellation dialog overlay.
class EmergencyCancellationDialog extends StatelessWidget {
  const EmergencyCancellationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final emergencyService = EmergencyService.instance;

    return ListenableBuilder(
      listenable: emergencyService,
      builder: (context, _) {
        final secondsLeft = emergencyService.cancellationSecondsLeft;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: AppColors.danger,
                    size: 36,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Emergency alert preparing...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'SMS will be sent automatically in $secondsLeft seconds.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Countdown Progress Indicator
                LinearProgressIndicator(
                  value: (5 - secondsLeft + 1) / 5.0,
                  backgroundColor: Colors.grey.shade200,
                  color: AppColors.danger,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Big Cancel Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      emergencyService.cancelEmergency();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
                    label: Text(
                      'Cancel ($secondsLeft s)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
