import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_client.dart';
import '../network/listing_api.dart';
import 'listing_filters.dart';

class ApiListingView extends ConsumerStatefulWidget {
  const ApiListingView({
    super.key,
    required this.endpoint,
    required this.filters,
    required this.itemBuilder,
    this.events = false,
    this.dateFilters = false,
    this.defaults = const {},
    this.includeRow,
  });
  final String endpoint;
  final List<ListingFilter> filters;
  final Widget Function(BuildContext, Map<String, dynamic>, VoidCallback)
  itemBuilder;
  final bool events, dateFilters;
  final Map<String, String> defaults;
  final bool Function(Map<String, dynamic>)? includeRow;
  @override
  ConsumerState<ApiListingView> createState() => ApiListingViewState();
}

class ApiListingViewState extends ConsumerState<ApiListingView> {
  Map<String, String> _filters = {};
  ListingPage? _result;
  Object? _error;
  int _page = 1;
  int _generation = 0;
  bool _loading = true;
  CancelToken? _cancel;
  @override
  void initState() {
    super.initState();
    _filters = Map.of(widget.defaults);
    Future.microtask(reload);
  }

  @override
  void dispose() {
    _cancel?.cancel();
    super.dispose();
  }

  Future<void> reload() async {
    if (!mounted) return;
    final generation = ++_generation;
    _cancel?.cancel();
    _cancel = CancelToken();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ListingApi(ref.read(dioProvider)).fetch(
        widget.endpoint,
        page: widget.events ? 1 : _page,
        filters: {
          ...widget.defaults,
          ..._filters,
          if (widget.events)
            'is_active':
                _filters['is_active'] ??
                widget.defaults['is_active'] ??
                'false',
        },
        cancelToken: _cancel,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _result = result;
        if (widget.events) {
          final count = result.rows
              .where((row) => widget.includeRow?.call(row) ?? true)
              .length;
          _page = _page.clamp(1, ((count + 19) ~/ 20).clamp(1, 1000000));
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _go(int page) {
    setState(() => _page = page);
    if (!widget.events) reload();
  }

  @override
  Widget build(BuildContext context) {
    final all = (_result?.rows ?? [])
        .where((r) => widget.includeRow?.call(r) ?? true)
        .toList();
    final totalPages = widget.events
        ? ((all.length + 19) ~/ 20).clamp(1, 1000000)
        : _result?.totalPages ?? 1;
    final rows = widget.events
        ? all.skip((_page - 1) * 20).take(20).toList()
        : all;
    return Column(
      children: [
        Flexible(
          flex: 0,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .38,
            ),
            child: SingleChildScrollView(
              child: ListingFilters(
                fields: widget.filters,
                values: _filters,
                dates: widget.events || widget.dateFilters,
                dateRangeLabel: widget.dateFilters
                    ? 'Announcement date range'
                    : 'Event date range',
                dateRangeHelp: widget.dateFilters
                    ? 'Only announcements fully contained in this date range appear.'
                    : 'Events starting and ending within this range. Boundaries use UTC dates.',
                onChanged: (filters) {
                  _filters = filters;
                  _page = 1;
                  reload();
                },
              ),
            ),
          ),
        ),
        if (_result != null && _result!.counts.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final status in const {
                  'WAITING_FOR_APPROVAL': 'Pending',
                  'APPROVED': 'Approved',
                  'REJECTED': 'Rejected',
                  'CANCELLED': 'Cancelled',
                }.entries)
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: ActionChip(
                      label: Text(
                        '${status.value}: ${_result!.counts[status.key] ?? 0}',
                      ),
                      onPressed: () {
                        _filters['by_status'] = status.key;
                        _page = 1;
                        reload();
                      },
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$_error'),
                        TextButton(
                          onPressed: reload,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: reload,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: rows.isEmpty ? 1 : rows.length,
                    itemBuilder: (context, index) => rows.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: Text('No matching records')),
                          )
                        : widget.itemBuilder(context, rows[index], reload),
                  ),
                ),
        ),
        if (!_loading && _error == null && totalPages > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Previous page',
                onPressed: _page > 1 ? () => _go(_page - 1) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('Page $_page of $totalPages'),
              IconButton(
                tooltip: 'Next page',
                onPressed: _page < totalPages ? () => _go(_page + 1) : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
      ],
    );
  }
}
