import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class FloatingLocationButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isLocating;

  const FloatingLocationButton({
    super.key,
    required this.onPressed,
    this.isLocating = false,
  });

  @override
  State<FloatingLocationButton> createState() => _FloatingLocationButtonState();
}

class _FloatingLocationButtonState extends State<FloatingLocationButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final double pulseOpacity = widget.isLocating
            ? (0.1 + (_pulseController.value * 0.25))
            : 0.0;
        final double pulseRadius = widget.isLocating
            ? (4.0 + (_pulseController.value * 8.0))
            : 0.0;

        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              if (widget.isLocating)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: pulseOpacity),
                  blurRadius: 16 + pulseRadius,
                  spreadRadius: pulseRadius,
                ),
              ...AppColors.floatingShadow,
            ],
          ),
          child: Material(
            color: AppColors.surface,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: widget.onPressed,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: AppSpacing.iconButtonSize,
                height: AppSpacing.iconButtonSize,
                child: Center(
                  child: widget.isLocating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        )
                      : const Icon(
                          Icons.my_location_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
