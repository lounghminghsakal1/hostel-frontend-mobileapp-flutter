enum LeaveStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected'),
  cancelled('Cancelled'),
  unknown('Unknown');

  const LeaveStatus(this.label);

  final String label;

  /// The value the review endpoint expects (`APPROVED` / `REJECTED`).
  String get apiValue => name.toUpperCase();

  static LeaveStatus fromApi(Object? value) => switch (value?.toString().toUpperCase()) {
        'PENDING' => pending,
        'APPROVED' => approved,
        'REJECTED' => rejected,
        'CANCELLED' || 'CANCELED' => cancelled,
        _ => unknown,
      };
}

class LeaveApplicationModel {
  const LeaveApplicationModel({
    required this.id,
    required this.leaveReason,
    required this.fromDate,
    required this.toDate,
    required this.status,
    this.rejectionReason,
    this.createdAt,
    this.reviewedAt,
    this.studentName,
    this.rollNumber,
    this.roomNumber,
  });

  final int id;
  final String leaveReason;

  /// Calendar dates only (local midnight), so timezones can't shift the day.
  final DateTime fromDate;
  final DateTime toDate;
  final LeaveStatus status;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? reviewedAt;

  /// Only filled for the admin, when the backend includes the student.
  final String? studentName;
  final String? rollNumber;
  final String? roomNumber;

  /// Inclusive day count, e.g. 3 Oct – 3 Oct is 1 day.
  int get days => toDate.difference(fromDate).inDays + 1;

  /// Students can edit or cancel, and admins review, only pending ones.
  bool get isPending => status == LeaveStatus.pending;

  /// Fields may come flat or nested under `student` / `student.room`.
  factory LeaveApplicationModel.fromJson(Map<String, dynamic> json) {
    final student = _map(json['student']);
    final room = _map(json['room'] ?? student?['room']);
    return LeaveApplicationModel(
      id: _asInt(json['id'])!,
      leaveReason: json['leaveReason']?.toString() ?? '',
      fromDate: _asDate(json['fromDate']) ?? DateTime.now(),
      toDate: _asDate(json['toDate']) ?? DateTime.now(),
      status: LeaveStatus.fromApi(json['status']),
      rejectionReason: _nonEmpty(json['rejectionReason']),
      createdAt: _asTimestamp(json['createdAt']),
      reviewedAt: _asTimestamp(json['reviewedAt']),
      studentName: _nonEmpty(json['studentName'] ?? student?['studentName']),
      rollNumber: _nonEmpty(json['rollNumber'] ?? student?['rollNumber']),
      roomNumber: _nonEmpty(json['roomNumber'] ?? room?['roomNumber']),
    );
  }
}

Map<String, dynamic>? _map(Object? value) => value is Map<String, dynamic> ? value : null;

String? _nonEmpty(Object? value) {
  final s = value?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

int? _asInt(Object? value) => switch (value) {
      int v => v,
      num v => v.toInt(),
      String v => int.tryParse(v),
      _ => null,
    };

/// Reads only the `yyyy-mm-dd` part of a date or ISO timestamp.
DateTime? _asDate(Object? value) {
  final s = value?.toString() ?? '';
  return s.length >= 10 ? DateTime.tryParse(s.substring(0, 10)) : null;
}

DateTime? _asTimestamp(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString())?.toLocal();
