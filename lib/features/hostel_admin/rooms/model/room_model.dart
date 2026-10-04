class RoomModel {
  const RoomModel({
    required this.id,
    required this.roomNumber,
    this.capacity,
  });

  final int id;
  final String roomNumber;
  final int? capacity;

  factory RoomModel.fromJson(Map<String, dynamic> json) => RoomModel(
        id: (json['id'] as num).toInt(),
        roomNumber: json['roomNumber']?.toString() ?? '',
        capacity: switch (json['capacity']) {
          num v => v.toInt(),
          String v => int.tryParse(v),
          _ => null,
        },
      );
}
