import 'marked_student_model.dart';

class AdminDashboardModel {
  const AdminDashboardModel({
    required this.hostelName,
    required this.dateLabel,
    required this.totalStudents,
    required this.markedPresent,
    required this.notMarked,
    required this.markedStudents,
  });

  final String hostelName;
  final String dateLabel;
  final int totalStudents;
  final int markedPresent;
  final int notMarked;
  final List<MarkedStudentModel> markedStudents;

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardModel(
      hostelName: json['hostelName'] as String,
      dateLabel: json['dateLabel'] as String,
      totalStudents: json['totalStudents'] as int,
      markedPresent: json['markedPresent'] as int,
      notMarked: json['notMarked'] as int,
      markedStudents: (json['markedStudents'] as List<dynamic>)
          .map((s) => MarkedStudentModel.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
