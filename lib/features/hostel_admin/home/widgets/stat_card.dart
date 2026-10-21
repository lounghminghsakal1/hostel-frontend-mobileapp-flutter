import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// A number tile for a single attendance metric (e.g. total/present/absent
/// students). [filled] highlights the primary metric with the brand
/// gradient; otherwise it reads as a plain white stat tile.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.filled = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.md + 2),
      decoration: BoxDecoration(
        gradient: filled ? AppColors.primaryGradient : null,
        color: filled ? null : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: filled ? null : Border.all(color: AppColors.navyAlpha(0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyAlpha(filled ? 0.22 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: filled ? AppColors.white : AppColors.brassDeep,
          ),
          const SizedBox(height: AppSpacing.md + 2),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              color: filled ? AppColors.white : AppColors.navy,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: filled ? AppColors.white.withValues(alpha: 0.8) : AppColors.navyAlpha(0.55),
            ),
          ),
        ],
      ),
    );
  }
}
