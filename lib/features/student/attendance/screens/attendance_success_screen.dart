import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/hostel_colors.dart';
import '../../../../core/utils/date_format.dart';

class AttendanceSuccessScreen extends StatefulWidget {
  const AttendanceSuccessScreen({
    super.key,
    required this.markedAt,
    this.windowOpensAt,
    this.windowClosesAt,
  });
  final DateTime markedAt;
  final DateTime? windowOpensAt, windowClosesAt;
  @override
  State<AttendanceSuccessScreen> createState() =>
      _AttendanceSuccessScreenState();
}

class _AttendanceSuccessScreenState extends State<AttendanceSuccessScreen> {
  Timer? _timer;
  bool _closing = false;
  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), _returnHome);
  }

  void _returnHome() {
    if (!mounted || _closing) return;
    _closing = true;
    _timer?.cancel();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<HostelColors>() ?? HostelColors.light;
    final date = indiaWallTime(widget.markedAt);
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 14, top: 6),
                child: IconButton(
                  tooltip: 'Back to home',
                  onPressed: _returnHome,
                  icon: Icon(Icons.close_rounded, color: c.ink),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 38, 20, 24),
                child: Column(
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        color: c.successSoft,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: c.success,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 40,
                          color: c.onSuccess,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'Attendance marked',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.ink,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${weekdays[date.weekday - 1]}, ${toDisplayDate(date)} \u00b7 ${toDisplayTime(date)}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.inkMuted, fontSize: 14),
                    ),
                    const SizedBox(height: 36),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: c.surfaceRaised,
                        border: Border.all(color: c.line),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          _detail('Photo', 'Captured', c),
                          const SizedBox(height: 16),
                          _detail('Location', 'At the hostel', c),
                          if (widget.windowOpensAt != null &&
                              widget.windowClosesAt != null) ...[
                            const SizedBox(height: 16),
                            _detail(
                              "Tonight's window",
                              '${toDisplayTime(indiaWallTime(widget.windowOpensAt!))} \u2013 ${toDisplayTime(indiaWallTime(widget.windowClosesAt!))}',
                              c,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "One mark a day. You're done for tonight.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.inkMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: FilledButton(
                onPressed: _returnHome,
                style: FilledButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: c.onPrimary,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back to home',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(String label, String value, HostelColors c) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(label, style: TextStyle(color: c.inkMuted, fontSize: 13)),
      ),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: c.ink,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}
