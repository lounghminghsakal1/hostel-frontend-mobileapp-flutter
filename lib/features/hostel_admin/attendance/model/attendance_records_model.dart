enum AttendanceStatusFilter {
  present,
  absent;

  String get queryValue => name;
}

/// Filters sent as query params to `GET /attendance_records`. Either [date]
/// or both [fromDate] and [toDate] are set, never both. Records compare by
/// value, so this works as a provider family key.
typedef AttendanceQuery = ({
  String? date,
  String? fromDate,
  String? toDate,
  AttendanceStatusFilter status,
  int page,
  int pageSize,
});

class AttendanceSummary {
  const AttendanceSummary({
    required this.totalStudents,
    required this.presentCount,
    required this.absentCount,
  });

  final int totalStudents;

  /// Students with at least one present record in the date filter.
  final int presentCount;

  /// Students with no present record at all in the date filter.
  final int absentCount;

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) => AttendanceSummary(
        totalStudents: _asInt(json['totalStudentsOfTheHostel']) ?? 0,
        presentCount: _asInt(json['totalStudentsWithatleastOnePresentDuringDateFilter']) ?? 0,
        absentCount: _asInt(json['completelyAbsentStudentsCountDuringDates']) ?? 0,
      );
}

/// One attendance-marked row (status = present).
class PresentAttendanceRecord {
  const PresentAttendanceRecord({
    required this.studentName,
    required this.rollNumber,
    required this.roomNumber,
    required this.attendanceDate,
    required this.capturedImageKey,
    required this.faceMatchingPercentage,
    required this.locationDeviationFromHostel,
    required this.isLocatedWithinHostelRadius,
    required this.latitude,
    required this.longitude,
  });

  final String studentName;
  final String rollNumber;
  final String? roomNumber;
  final String? attendanceDate;
  /// S3 key of the capture; exchanged for a download url only when viewed.
  final String? capturedImageKey;
  final double? faceMatchingPercentage;

  /// Distance from the hostel, in metres.
  final double? locationDeviationFromHostel;
  final bool isLocatedWithinHostelRadius;
  final double? latitude;
  final double? longitude;

  /// Fields may come flat or nested under `student` / `student.room`.
  factory PresentAttendanceRecord.fromJson(Map<String, dynamic> json) {
    final student = _map(json['student']);
    return PresentAttendanceRecord(
      studentName: (json['studentName'] ?? student?['studentName'])?.toString() ?? '',
      rollNumber: (json['rollNumber'] ?? student?['rollNumber'])?.toString() ?? '',
      roomNumber: _roomNumber(json, student),
      attendanceDate: json['attendanceDate']?.toString(),
      capturedImageKey: json['capturedImageKey'] as String?,
      faceMatchingPercentage: _asDouble(json['faceMatchingPercentage']),
      locationDeviationFromHostel: _asDouble(json['locationDeviationFromHostel']),
      isLocatedWithinHostelRadius: json['isLocatedWithinHostelRadius'] == true,
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
    );
  }

  Uri? get mapUri => (latitude == null || longitude == null)
      ? null
      : Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': '$latitude,$longitude'});
}

/// One absent row (status = absent): a student absent on at least one day.
class AbsentAttendanceRecord {
  const AbsentAttendanceRecord({
    required this.studentName,
    required this.rollNumber,
    required this.roomNumber,
    required this.departmentName,
    required this.absentDates,
  });

  final String studentName;
  final String rollNumber;
  final String? roomNumber;
  final String? departmentName;
  final List<String> absentDates;

  factory AbsentAttendanceRecord.fromJson(Map<String, dynamic> json) {
    final student = _map(json['student']);
    final department = json['department'] ?? student?['department'];
    final dates = json['absentDates'];
    return AbsentAttendanceRecord(
      studentName: (json['studentName'] ?? student?['studentName'])?.toString() ?? '',
      rollNumber: (json['rollNumber'] ?? student?['rollNumber'])?.toString() ?? '',
      roomNumber: _roomNumber(json, student),
      departmentName: switch (department) {
        Map<String, dynamic> d => d['departmentName']?.toString(),
        String d => d,
        _ => json['departmentName']?.toString(),
      },
      absentDates: dates is List ? dates.map((d) => d.toString()).toList() : const [],
    );
  }
}

/// The response's top-level `meta`: `{page, pageSize, totalPages}`.
class PaginationMeta {
  const PaginationMeta({required this.page, required this.totalPages, this.totalCount});

  final int page;
  final int totalPages;

  /// Only present if the backend sends one.
  final int? totalCount;

  factory PaginationMeta.fromJson(Map<String, dynamic>? json, {required int fallbackPage, required int pageSize}) {
    final totalCount = _asInt(json?['totalCount'] ?? json?['total']);
    final computedPages = (totalCount != null && pageSize > 0) ? (totalCount / pageSize).ceil() : 1;
    final totalPages = _asInt(json?['totalPages']) ?? computedPages;
    return PaginationMeta(
      page: _asInt(json?['page']) ?? fallbackPage,
      totalPages: totalPages < 1 ? 1 : totalPages,
      totalCount: totalCount,
    );
  }
}

/// Parsed `GET /attendance_records` response. Exactly one of the record
/// lists is filled, depending on the requested status.
class AttendanceRecordsResult {
  const AttendanceRecordsResult({
    required this.summary,
    required this.presentRecords,
    required this.absentRecords,
    required this.pagination,
  });

  final AttendanceSummary summary;
  final List<PresentAttendanceRecord> presentRecords;
  final List<AbsentAttendanceRecord> absentRecords;
  final PaginationMeta pagination;

  /// [data] is the response's `data` (`{summary, attendanceRecords}`) and
  /// [meta] its top-level `meta`.
  factory AttendanceRecordsResult.fromJson(
    Map<String, dynamic> data,
    Map<String, dynamic>? meta,
    AttendanceQuery query,
  ) {
    final rows = (data['attendanceRecords'] as List<dynamic>? ?? const [])
        .map((r) => r as Map<String, dynamic>)
        .toList();
    final isAbsent = query.status == AttendanceStatusFilter.absent;
    return AttendanceRecordsResult(
      summary: AttendanceSummary.fromJson(_map(data['summary']) ?? const {}),
      presentRecords: isAbsent ? const [] : rows.map(PresentAttendanceRecord.fromJson).toList(),
      absentRecords: isAbsent ? rows.map(AbsentAttendanceRecord.fromJson).toList() : const [],
      pagination: PaginationMeta.fromJson(
        meta,
        fallbackPage: query.page,
        pageSize: query.pageSize,
      ),
    );
  }
}

String? _roomNumber(Map<String, dynamic> json, Map<String, dynamic>? student) {
  final room = _map(json['room'] ?? student?['room']);
  return (json['roomNumber'] ?? room?['roomNumber'])?.toString();
}

Map<String, dynamic>? _map(Object? value) => value is Map<String, dynamic> ? value : null;

int? _asInt(Object? value) => switch (value) {
      int v => v,
      num v => v.toInt(),
      String v => int.tryParse(v),
      _ => null,
    };

double? _asDouble(Object? value) => switch (value) {
      num v => v.toDouble(),
      String v => double.tryParse(v),
      _ => null,
    };
