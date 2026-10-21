import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A tappable navigation card used for "quick link" shortcuts on home
/// screens (e.g. "Manage Students", "Upcoming Events"). White surface,
/// brass icon badge, with a brief tap-scale for feedback.
class QuickLinkCard extends StatefulWidget {
  const QuickLinkCard({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.count,
    required this.onTap,
  });

  final IconData icon;
  final String label;

  /// Supporting line shown under [label]. Ignored when [count] is set.
  final String? subtitle;

  /// Optional count/number shown as a trailing badge instead of a subtitle.
  final String? count;

  final VoidCallback onTap;

  @override
  State<QuickLinkCard> createState() => _QuickLinkCardState();
}

class _QuickLinkCardState extends State<QuickLinkCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.navyAlpha(0.08)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: widget.onTap,
            onTapDown: (_) => _setPressed(true),
            onTapCancel: () => _setPressed(false),
            onTapUp: (_) => _setPressed(false),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm + 2),
                    decoration: BoxDecoration(
                      color: AppColors.brassSoft,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(widget.icon, color: AppColors.brassDeep, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md + 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: textTheme.titleMedium?.copyWith(fontSize: 14.5),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            widget.subtitle!,
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.count != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.navySoft,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        widget.count!,
                        style: textTheme.labelSmall?.copyWith(color: AppColors.navy),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.navyAlpha(0.45),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
