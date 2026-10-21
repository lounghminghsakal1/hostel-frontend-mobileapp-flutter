import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Labeled destinations with keyboard, screen-reader and touch support.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.labels,
    this.activeIndex = 0,
    required this.onItemTap,
  }) : assert(items.length == labels.length);

  final List<IconData> items;
  final List<String> labels;
  final int activeIndex;
  final ValueChanged<int> onItemTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.navyAlpha(0.08))),
      ),
      child: NavigationBar(
        selectedIndex: activeIndex,
        onDestinationSelected: onItemTap,
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.brassSoft,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: List.generate(items.length, (index) {
          return NavigationDestination(
            icon: Icon(items[index], color: AppColors.navyAlpha(0.45)),
            selectedIcon: Icon(items[index], color: AppColors.brassDeep),
            label: labels[index],
            tooltip: labels[index],
          );
        }),
      ),
    );
  }
}
