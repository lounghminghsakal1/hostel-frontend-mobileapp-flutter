import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../data/announcements_repository.dart';
import '../model/announcement_model.dart';

final announcementsRepositoryProvider = Provider<AnnouncementsRepository>(
  (ref) => AnnouncementsRepository(ref.watch(dioProvider)),
);
final studentAnnouncementsProvider =
    FutureProvider.autoDispose<List<AnnouncementModel>>(
      (ref) =>
          ref.watch(announcementsRepositoryProvider).studentAnnouncements(),
    );
final announcementDetailProvider = FutureProvider.autoDispose
    .family<AnnouncementModel, int>(
      (ref, id) => ref.watch(announcementsRepositoryProvider).get(id),
    );
