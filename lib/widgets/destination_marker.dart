import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DestinationMarkerWidget extends StatelessWidget {
  final String? label;

  const DestinationMarkerWidget({
    super.key,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              color: AppColors.textPrimary,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
            ),
            child: Text(
              label!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: AppColors.floatingShadow,
          ),
          child: const Center(
            child: Icon(
              Icons.place_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
}

class CurrentLocationMarkerWidget extends StatelessWidget {
  const CurrentLocationMarkerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: Color.fromRGBO(37, 99, 235, 0.18),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: AppColors.softShadow,
          ),
        ),
      ),
    );
  }
}
