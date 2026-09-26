class MarkedStudentModel {
  const MarkedStudentModel({
    required this.name,
    required this.rollNumber,
    required this.roomNumber,
    required this.time,
    required this.faceMatch,
    required this.initials,
  });

  final String name;
  final String rollNumber;
  final String roomNumber;
  final String time;
  final int faceMatch;
  final String initials;

  factory MarkedStudentModel.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String;
    return MarkedStudentModel(
      name: name,
      rollNumber: json['rollNumber'] as String,
      roomNumber: json['roomNumber'] as String,
      time: json['time'] as String,
      faceMatch: json['faceMatch'] as int,
      initials: _initialsOf(name),
    );
  }

  static String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}
