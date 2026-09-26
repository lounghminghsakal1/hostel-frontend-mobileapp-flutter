import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    this.activeIndex = 0,
    this.onItemTap,
  });

  final List<IconData> items;
  final int activeIndex;

  /// Called with the tapped index for inactive items. Return `true` if the
  /// tap was handled; unhandled taps show a "Coming soon" hint.
  final bool Function(int index)? onItemTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.navyAlpha(0.08)),
          boxShadow: [
            BoxShadow(
              color: AppColors.navyAlpha(0.12),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final isActive = index == activeIndex;
            return GestureDetector(
              onTap: () {
                if (!isActive && !(onItemTap?.call(index) ?? false)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Coming soon'),
                      duration: Duration(milliseconds: 900),
                    ),
                  );
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  gradient: isActive ? AppColors.primaryGradient : null,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  items[index],
                  size: 22,
                  color: isActive ? AppColors.white : AppColors.navyAlpha(0.4),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
