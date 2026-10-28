import '../../../../core/utils/date_format.dart';
import '../../../common/announcements/model/announcement_model.dart';
import '../../../common/upcoming_events/model/upcoming_event_model.dart';

enum AttendanceCardState {
  open,
  marked,
  upcoming,
  missed,
  photoNeeded,
  unavailable,
}

class StudentHomeModel {
  const StudentHomeModel({
    required this.canMarkAttendance,
    this.studentName,
    this.roomNumber,
    this.hostelName,
    this.hasProfilePhoto,
    this.markedAt,
    this.isMarkedToday = false,
    this.windowOpensAt,
    this.windowClosesAt,
    this.accountEmail,
    this.accountStatus,
    this.roleName,
    this.userId,
    this.roleId,
    this.studentProfileId,
    this.hostelId,
    this.announcements = const [],
    this.upcomingEvents = const [],
  });
  final bool canMarkAttendance, isMarkedToday;
  final String? studentName, roomNumber, hostelName;
  final bool? hasProfilePhoto;
  final DateTime? markedAt, windowOpensAt, windowClosesAt;
  final String? accountEmail, accountStatus, roleName;
  final int? userId, roleId, studentProfileId, hostelId;
  final List<AnnouncementModel> announcements;
  final List<UpcomingEventModel> upcomingEvents;
  AttendanceCardState attendanceState(
    DateTime now, {
    DateTime? locallyMarkedAt,
  }) {
    bool today(DateTime value) {
      final a = indiaWallTime(value), b = indiaWallTime(now);
      return a.year == b.year && a.month == b.month && a.day == b.day;
    }

    if (isMarkedToday ||
        (markedAt != null && today(markedAt!)) ||
        (locallyMarkedAt != null && today(locallyMarkedAt))) {
      return AttendanceCardState.marked;
    }
    if (hasProfilePhoto == false) return AttendanceCardState.photoNeeded;
    if (windowOpensAt != null && now.isBefore(windowOpensAt!)) {
      return AttendanceCardState.upcoming;
    }
    if (windowClosesAt != null && !now.isBefore(windowClosesAt!)) {
      return AttendanceCardState.missed;
    }
    if (canMarkAttendance) return AttendanceCardState.open;
    return AttendanceCardState.unavailable;
  }

  String get initials {
    final parts =
        studentName
            ?.trim()
            .split(RegExp(r'\s+'))
            .where((p) => p.isNotEmpty)
            .toList() ??
        [];
    final emailName = accountEmail?.split('@').first.trim();
    return parts.isEmpty
        ? (emailName == null || emailName.isEmpty
              ? 'ST'
              : emailName[0].toUpperCase())
        : '${parts.first[0]}${parts.length > 1 ? parts.last[0] : ''}'
              .toUpperCase();
  }

  factory StudentHomeModel.fromJson(Map<String, dynamic> json) {
    if (json['announcements'] is! List || json['upcomingEvents'] is! List) {
      throw const FormatException(
        'Student splash response must include announcement and event arrays',
      );
    }
    final user = json['user'] as Map? ?? const {};
    final student = user['studentProfile'] as Map? ?? const {};
    final hostel = json['hostel'] as Map? ?? const {};
    DateTime? instant(Object? value) =>
        DateTime.tryParse(value?.toString() ?? '');
    DateTime? todayAt(Object? value) {
      final text = value?.toString();
      if (text == null) return null;
      final parts = text.split(':');
      if (parts.length < 2) return instant(value);
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null || hour > 23 || minute > 59) {
        return null;
      }
      final wallNow = indiaWallTime(DateTime.now());
      return indiaPickerToInstant(
        DateTime(wallNow.year, wallNow.month, wallNow.day, hour, minute),
      );
    }

    final opensAt = todayAt(hostel['attendanceMarkingStartTime']);
    var closesAt = todayAt(hostel['attendanceMarkingEndTime']);
    if (opensAt != null && closesAt != null && !closesAt.isAfter(opensAt)) {
      closesAt = closesAt.add(const Duration(days: 1));
    }
    final announcementRows = json['announcements'] as List;
    final eventRows = json['upcomingEvents'] as List;
    int? id(Object? value) =>
        value is num ? value.toInt() : int.tryParse('$value');
    return StudentHomeModel(
      canMarkAttendance: json['canMarkAttendance'] == true,
      studentName: student['studentName'] as String?,
      roomNumber: student['roomNumber']?.toString(),
      hostelName: hostel['hostelName']?.toString(),
      hasProfilePhoto: student['studentImageKey']?.toString().trim().isNotEmpty,
      // The splash has no attendance-recorded boolean or timestamp. A false
      // canMarkAttendance value alone must never be presented as marked.
      isMarkedToday: false,
      markedAt: null,
      windowOpensAt: opensAt,
      windowClosesAt: closesAt,
      accountEmail: user['email']?.toString(),
      accountStatus: user['status']?.toString(),
      roleName: (user['role'] as Map?)?['roleName']?.toString(),
      userId: id(user['id']),
      roleId: id((user['role'] as Map?)?['id']),
      studentProfileId: id(student['id']),
      hostelId: id(hostel['id']),
      announcements: announcementRows
          .map(
            (row) => AnnouncementModel.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList(),
      upcomingEvents: eventRows
          .map(
            (row) => UpcomingEventModel.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList(),
    );
  }
}
