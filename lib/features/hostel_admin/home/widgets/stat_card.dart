import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        gradient: filled ? AppColors.primaryGradient : null,
        color: filled ? null : AppColors.white,
        borderRadius: BorderRadius.circular(18),
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
            color: filled ? AppColors.white : AppColors.navy,
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              color: filled ? AppColors.white : AppColors.navy,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: filled ? AppColors.white.withValues(alpha: 0.8) : AppColors.navyAlpha(0.55),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
