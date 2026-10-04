const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String _two(int n) => n.toString().padLeft(2, '0');

/// `2026-09-26`, the format the API expects for date query params.
String toIsoDate(DateTime date) => '${date.year}-${_two(date.month)}-${_two(date.day)}';

/// `26 Sep 2026`, for showing a date to the user.
String toDisplayDate(DateTime date) => '${date.day} ${_months[date.month - 1]} ${date.year}';

/// Formats a date the API sent (`2026-09-26` or a full ISO timestamp) for
/// display, reading only its calendar date so timezones can't shift the day.
/// `5:30 PM`, in the device's local time.
String toDisplayTime(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  return '$hour:${_two(time.minute)} ${time.hour < 12 ? 'AM' : 'PM'}';
}

/// `26 Sep 2026, 5:30 PM`.
String toDisplayDateTime(DateTime time) => '${toDisplayDate(time)}, ${toDisplayTime(time)}';

String apiDateToDisplay(String value) {
  final parsed = value.length >= 10 ? DateTime.tryParse(value.substring(0, 10)) : null;
  return parsed == null ? value : toDisplayDate(parsed);
}
