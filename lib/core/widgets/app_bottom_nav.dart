import 'package:flutter/material.dart';

import '../theme/hostel_colors.dart';

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
    final c = Theme.of(context).extension<HostelColors>() ?? HostelColors.light;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: NavigationBar(
        height: 76,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? c.ink : c.inkMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        selectedIndex: activeIndex,
        onDestinationSelected: onItemTap,
        backgroundColor: c.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.marigoldSoft,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: List.generate(items.length, (index) {
          return NavigationDestination(
            icon: Icon(items[index], color: c.inkMuted),
            selectedIcon: Icon(items[index], color: c.marigoldInk),
            label: labels[index],
            tooltip: labels[index],
          );
        }),
      ),
    );
  }
}
