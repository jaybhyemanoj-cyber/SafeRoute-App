import 'package:flutter/material.dart';
import '../models/hazard_report.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Compact horizontal category filter for map hazards.
class HazardFilterBar extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const HazardFilterBar({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'key': 'all', 'label': 'Show All', 'emoji': '📍'},
      ...HazardReport.hazardCategories,
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final item = categories[index];
          final key = item['key'] as String;
          final label = item['label'] as String;
          final emoji = item['emoji'] as String;
          final isSelected = selectedCategory == key;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onCategorySelected(key),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryDark : AppColors.border,
                    width: 1,
                  ),
                  boxShadow: AppColors.softShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      emoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      label,
                      style: AppTypography.caption.copyWith(
                        color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
