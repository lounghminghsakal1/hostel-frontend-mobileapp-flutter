import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/media_download_url.dart';
import '../../../../core/theme/app_colors.dart';
import '../model/upcoming_event_model.dart';

/// An event's banner: the url the backend sent, else a presigned url for its
/// image key, falling back to a navy placeholder.
class EventImage extends ConsumerWidget {
  const EventImage({super.key, required this.event, this.iconSize = 36});

  final UpcomingEventModel event;
  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final directUrl = event.eventImageUrl;
    if (directUrl != null) return _network(directUrl);

    final key = event.eventImageKey;
    if (key == null) return _placeholder();

    return ref.watch(mediaDownloadUrlProvider(key)).when(
          loading: () => _placeholder(loading: true),
          error: (_, _) => _placeholder(),
          data: _network,
        );
  }

  Widget _network(String url) => Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) => progress == null ? child : _placeholder(loading: true),
        errorBuilder: (_, _, _) => _placeholder(),
      );

  Widget _placeholder({bool loading = false}) => Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.white),
              )
            : Icon(Icons.celebration_outlined, color: AppColors.white.withValues(alpha: 0.85), size: iconSize),
      );
}
