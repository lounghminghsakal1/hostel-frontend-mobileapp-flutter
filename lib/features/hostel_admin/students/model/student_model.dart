class StudentModel {
  const StudentModel({
    required this.id,
    required this.studentName,
    required this.email,
    required this.contactNumber,
    required this.parentMobileNumber,
    required this.departmentId,
    this.departmentName,
    this.roomId,
    this.roomNumber,
    this.studentImageKey,
    this.studentImageUrl,
  });

  final int id;
  final String studentName;
  final String email;
  final String contactNumber;
  final String parentMobileNumber;
  final int? departmentId;
  final String? departmentName;
  final int? roomId;
  final String? roomNumber;
  final String? studentImageKey;

  /// Viewable url for the profile photo, if the backend sends one.
  final String? studentImageUrl;

  String get initials {
    final parts = studentName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    final department = json['department'];
    final room = json['room'];
    return StudentModel(
      id: _asInt(json['id'])!,
      studentName: json['studentName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      contactNumber: json['contactNumber']?.toString() ?? '',
      parentMobileNumber: json['parentMobileNumber']?.toString() ?? '',
      departmentId: _asInt(json['departmentId']) ?? (department is Map ? _asInt(department['id']) : null),
      departmentName: department is Map ? (department['name'] ?? department['departmentName']) as String? : null,
      roomId: _asInt(json['roomId']) ?? (room is Map ? _asInt(room['id']) : null),
      roomNumber: room is Map ? (room['roomNumber'] ?? room['name'])?.toString() : null,
      studentImageKey: json['studentImageKey'] as String?,
      studentImageUrl: (json['studentImageUrl'] ?? json['imageUrl']) as String?,
    );
  }

  static int? _asInt(Object? value) => switch (value) {
        int v => v,
        num v => v.toInt(),
        String v => int.tryParse(v),
        _ => null,
      };
}
