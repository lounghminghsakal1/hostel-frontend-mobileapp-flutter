class UpcomingEventModel {
  const UpcomingEventModel({
    required this.id,
    required this.eventName,
    required this.eventDescription,
    required this.startingAt,
    required this.endingAt,
    required this.isActive,
    this.eventImageKey,
    this.eventImageUrl,
    this.eventLink,
    this.contactPersonName,
    this.contactPersonPhone,
  });

  final int id;
  final String eventName;
  final String eventDescription;

  /// Local time.
  final DateTime startingAt;
  final DateTime endingAt;

  /// Inactive events are hidden from students; only admins see them.
  final bool isActive;

  /// S3 key of the banner; exchanged for a download url when shown, unless
  /// the backend already sent [eventImageUrl].
  final String? eventImageKey;
  final String? eventImageUrl;
  final String? eventLink;
  final String? contactPersonName;
  final String? contactPersonPhone;

  bool get hasEnded => endingAt.isBefore(DateTime.now());

  bool get isOngoing => !hasEnded && startingAt.isBefore(DateTime.now());

  factory UpcomingEventModel.fromJson(Map<String, dynamic> json) {
    final startingAt = _asTimestamp(json['startingAt']) ?? DateTime.now();
    return UpcomingEventModel(
      id: _asInt(json['id'])!,
      eventName: json['eventName']?.toString() ?? '',
      eventDescription: json['eventDescription']?.toString() ?? '',
      startingAt: startingAt,
      endingAt: _asTimestamp(json['endingAt']) ?? startingAt,
      // Treat a missing flag as active, since only admins can deactivate.
      isActive: json['isActive'] != false,
      eventImageKey: _nonEmpty(json['eventImageKey']),
      eventImageUrl: _nonEmpty(json['eventImageUrl'] ?? json['imageUrl']),
      eventLink: _nonEmpty(json['eventLink']),
      contactPersonName: _nonEmpty(json['contactPersonName']),
      contactPersonPhone: _nonEmpty(json['contactPersonPhone']),
    );
  }
}

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

DateTime? _asTimestamp(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString())?.toLocal();
