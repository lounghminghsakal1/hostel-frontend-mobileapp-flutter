import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/network/s3_upload_service.dart';
import '../data/upcoming_events_repository.dart';
import '../model/upcoming_event_model.dart';

final upcomingEventsRepositoryProvider = Provider<UpcomingEventsRepository>((ref) {
  return UpcomingEventsRepository(ref.watch(dioProvider), ref.watch(s3UploadServiceProvider));
});

/// Sorted by start time, soonest first.
final upcomingEventsProvider = FutureProvider.autoDispose<List<UpcomingEventModel>>((ref) {
  return ref.watch(upcomingEventsRepositoryProvider).getUpcomingEvents();
});

final upcomingEventDetailProvider = FutureProvider.autoDispose.family<UpcomingEventModel, int>((ref, id) {
  return ref.watch(upcomingEventsRepositoryProvider).getUpcomingEvent(id);
});
