import 'package:flutter/material.dart';

import '../../../../core/theme/hostel_colors.dart';
import '../model/room_model.dart';

class RoomOccupancyCard extends StatelessWidget {
  const RoomOccupancyCard({super.key, required this.room, required this.onTap});

  final RoomModel room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<HostelColors>() ?? HostelColors.light;
    final capacity = room.capacity;
    final occupied = room.occupiedBeds;
    final free = room.freeBeds;
    final indicators = (capacity ?? 0).clamp(0, 30);
    return Semantics(
      button: true,
      label:
          'Room ${room.roomNumber}, ${occupied ?? 'unknown'} occupied '
          'of ${capacity ?? 'unknown'}, ${free ?? 'unknown'} beds free',
      child: Material(
        color: c.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: c.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  room.roomNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 12),
                ExcludeSemantics(
                  child: Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: [
                      for (var i = 0; i < indicators; i++)
                        Container(
                          width: 22,
                          height: 12,
                          decoration: BoxDecoration(
                            color: occupied != null && i < occupied
                                ? c.brand
                                : c.surfaceRaised,
                            border: Border.all(
                              color: occupied == null
                                  ? c.lineStrong
                                  : i < occupied
                                  ? c.brand
                                  : c.success,
                              width: 1.2,
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      if (capacity != null && capacity > indicators)
                        Text(
                          '+${capacity - indicators}',
                          style: TextStyle(color: c.inkMuted, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${occupied ?? '\u2014'} of ${capacity ?? '\u2014'}',
                        style: TextStyle(color: c.inkMuted, fontSize: 12),
                      ),
                    ),
                    if (free != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: free > 0 ? c.successSoft : c.surfaceSunken,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          free > 0 ? '$free free' : 'Full',
                          style: TextStyle(
                            color: free > 0 ? c.success : c.inkMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
