/// An id + display label pair for dropdowns, e.g. a department or a room.
class SelectOption {
  const SelectOption({required this.id, required this.label});

  final int id;
  final String label;

  /// Parses a `/students/departments` item: `{id, departmentName}`.
  factory SelectOption.department(Map<String, dynamic> json) => SelectOption(
        id: (json['id'] as num).toInt(),
        label: json['departmentName']?.toString() ?? 'Department ${json['id']}',
      );

  /// Parses a `/rooms` item: `{id, roomNumber}`.
  factory SelectOption.room(Map<String, dynamic> json) => SelectOption(
        id: (json['id'] as num).toInt(),
        label: json['roomNumber']?.toString() ?? 'Room ${json['id']}',
      );
}
