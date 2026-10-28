class RoomModel {
  const RoomModel({
    required this.id,
    required this.roomNumber,
    this.capacity,
    this.occupied,
    this.remaining,
  });

  final int id;
  final String roomNumber;
  final int? capacity;
  final int? occupied;
  final int? remaining;

  int? get occupiedBeds =>
      occupied ??
      (capacity != null && remaining != null
          ? (capacity! - remaining!).clamp(0, capacity!)
          : null);

  int? get freeBeds =>
      remaining ??
      (capacity != null && occupied != null
          ? (capacity! - occupied!).clamp(0, capacity!)
          : null);

  bool get hasFreeBeds => (freeBeds ?? 0) > 0;
  bool get isFull => capacity != null && capacity! > 0 && freeBeds == 0;

  factory RoomModel.fromJson(Map<String, dynamic> json) => RoomModel(
    id: (json['id'] as num).toInt(),
    roomNumber: json['roomNumber']?.toString() ?? '',
    capacity: switch (json['capacity']) {
      num v => v.toInt(),
      String v => int.tryParse(v),
      _ => null,
    },
    occupied: _asInt(json['occupied']),
    remaining: _asInt(json['remaining']),
  );
}

int? _asInt(Object? value) => switch (value) {
  num value => value.toInt(),
  String value => int.tryParse(value),
  _ => null,
};
