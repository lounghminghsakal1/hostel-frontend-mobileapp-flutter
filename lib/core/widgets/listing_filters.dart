import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/hostel_admin/students/providers/students_providers.dart';
import '../utils/date_format.dart';

class ListingFilter {
  const ListingFilter(
    this.key,
    this.label, {
    this.options,
    this.lookup,
    this.percentage = false,
  });
  final String key;
  final String label;
  final Map<String, String>? options;
  final String? lookup;
  final bool percentage;
}

const studentNameFilter = ListingFilter('by_student_name', 'Student name');
const studentFilters = [
  studentNameFilter,
  ListingFilter('by_roll_number', 'Exact roll number'),
  ListingFilter('by_department_id', 'Department', lookup: 'department'),
  ListingFilter('by_room_id', 'Room', lookup: 'room'),
];
const attendanceFilters = [
  studentNameFilter,
  ListingFilter('by_roll_number', 'Exact roll number'),
  ListingFilter('by_student_department_id', 'Department', lookup: 'department'),
  ListingFilter('by_student_room_id', 'Room', lookup: 'room'),
];
const leaveFilters = [
  studentNameFilter,
  ListingFilter('by_student_roll_number', 'Exact roll number'),
  ListingFilter('by_student_department_id', 'Department', lookup: 'department'),
  ListingFilter('by_student_room_id', 'Room', lookup: 'room'),
];
const roomFilters = [
  ListingFilter('starts_with', 'Room number prefix'),
  ListingFilter(
    'only_vacancy',
    'Vacancy',
    options: {'false': 'All rooms', 'true': 'Vacant rooms'},
  ),
  studentNameFilter,
  ListingFilter('by_student_roll_number', 'Exact student roll number'),
];
const eventFilters = [
  ListingFilter('by_event_name', 'Event name'),
  ListingFilter(
    'is_active',
    'Activity',
    options: {'false': 'All events', 'true': 'Active events'},
  ),
];

class ListingFilters extends ConsumerStatefulWidget {
  const ListingFilters({
    super.key,
    required this.fields,
    required this.onChanged,
    this.dates = false,
    this.values,
  });
  final List<ListingFilter> fields;
  final ValueChanged<Map<String, String>> onChanged;
  final bool dates;
  final Map<String, String>? values;
  @override
  ConsumerState<ListingFilters> createState() => _ListingFiltersState();
}

class _ListingFiltersState extends ConsumerState<ListingFilters> {
  final Map<String, String> _values = {};
  Timer? _timer;
  DateTimeRange? _range;
  @override
  void initState() {
    super.initState();
    _values.addAll(widget.values ?? {});
  }

  @override
  void didUpdateWidget(covariant ListingFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.values != null) {
      _values
        ..clear()
        ..addAll(widget.values!);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _change(String key, String? value, {bool debounce = false}) {
    _values[key] = value?.trim() ?? '';
    _timer?.cancel();
    void emit() => widget.onChanged(
      Map.of(_values)..removeWhere((key, value) => value.isEmpty),
    );
    if (debounce) {
      _timer = Timer(const Duration(milliseconds: 350), emit);
    } else {
      emit();
    }
  }

  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: const Text('Search and filters'),
    childrenPadding: const EdgeInsets.all(12),
    children: [
      for (final field in widget.fields)
        Padding(
          key: ValueKey(field.key),
          padding: const EdgeInsets.only(bottom: 12),
          child: _field(field),
        ),
      if (widget.dates)
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.date_range),
                label: Text(
                  _range == null
                      ? 'Event date range'
                      : '${toIsoDate(_range!.start)} – ${toIsoDate(_range!.end)}',
                ),
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    initialDateRange: _range,
                  );
                  if (range == null || !mounted) return;
                  setState(() => _range = range);
                  _values['from_date'] = toIsoDate(range.start);
                  _change('to_date', toIsoDate(range.end));
                },
              ),
            ),
            IconButton(
              tooltip: 'Clear dates',
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() => _range = null);
                _values.remove('from_date');
                _change('to_date', null);
              },
            ),
          ],
        ),
      if (widget.dates)
        const Text(
          'Events starting and ending within this range. Boundaries use UTC dates.',
        ),
    ],
  );
  Widget _field(ListingFilter field) {
    if (field.options != null) {
      return DropdownButtonFormField<String>(
        key: ValueKey('${field.key}:${_values[field.key]}'),
        initialValue: _values[field.key],
        isExpanded: true,
        decoration: InputDecoration(labelText: field.label),
        items: [
          const DropdownMenuItem(value: '', child: Text('Any')),
          for (final item in field.options!.entries)
            DropdownMenuItem(value: item.key, child: Text(item.value)),
        ],
        onChanged: (v) => _change(field.key, v),
      );
    }
    if (field.lookup != null) {
      final provider = field.lookup == 'room'
          ? roomsProvider
          : departmentsProvider;
      return ref
          .watch(provider)
          .when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => TextButton(
              onPressed: () => ref.invalidate(provider),
              child: Text('Retry ${field.label.toLowerCase()} options: $e'),
            ),
            data: (options) => DropdownButtonFormField<String>(
              initialValue: _values[field.key],
              isExpanded: true,
              decoration: InputDecoration(labelText: field.label),
              items: [
                const DropdownMenuItem(value: '', child: Text('Any')),
                for (final option in options)
                  DropdownMenuItem(
                    value: '${option.id}',
                    child: Text(option.label),
                  ),
              ],
              onChanged: (v) => _change(field.key, v),
            ),
          );
    }
    return TextFormField(
      decoration: InputDecoration(labelText: field.label),
      keyboardType: field.percentage
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (v) =>
          field.percentage &&
              v != null &&
              v.isNotEmpty &&
              (double.tryParse(v) == null ||
                  !double.parse(v).isFinite ||
                  double.parse(v) < 0 ||
                  double.parse(v) > 100)
          ? 'Enter a percentage from 0 to 100'
          : null,
      onChanged: (v) {
        if (field.percentage &&
            v.isNotEmpty &&
            (double.tryParse(v) == null ||
                !double.parse(v).isFinite ||
                double.parse(v) < 0 ||
                double.parse(v) > 100)) {
          return;
        }
        _change(field.key, v, debounce: true);
      },
    );
  }
}
