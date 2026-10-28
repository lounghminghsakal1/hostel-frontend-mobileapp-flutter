import 'package:flutter/material.dart';

import '../../../../core/theme/hostel_colors.dart';
import '../model/announcement_model.dart';

class AnnouncementTile extends StatelessWidget {
  const AnnouncementTile({
    super.key,
    required this.announcement,
    this.onTap,
    this.expanded = false,
    this.showStatus = false,
  });
  final AnnouncementModel announcement;
  final VoidCallback? onTap;
  final bool expanded, showStatus;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<HostelColors>() ?? HostelColors.light;
    final a = announcement;
    return Material(
      color: c.surfaceRaised,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (a.isImportant)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: c.dangerSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 14,
                            color: c.danger,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Important',
                            style: TextStyle(color: c.danger, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    '${a.category} \u00b7 ${a.dateLabel}',
                    style: TextStyle(color: c.inkMuted, fontSize: 12),
                  ),
                  if (showStatus)
                    Text(
                      a.status == 'ACTIVE' ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: a.status == 'ACTIVE' ? c.success : c.inkMuted,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      a.title,
                      style: TextStyle(
                        color: c.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (onTap != null)
                    Icon(Icons.chevron_right, color: c.inkMuted, size: 20),
                ],
              ),
              if (expanded) ...[
                const SizedBox(height: 8),
                Text(
                  a.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.inkMuted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
