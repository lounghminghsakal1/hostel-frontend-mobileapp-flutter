import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router/app_router.dart';
import '../router/app_routes.dart';

/// Listens for `ourhostel://` links (both the one that launched the app and
/// any received while it runs) and routes them. Watch it once from the app
/// root to start listening.
final deepLinkListenerProvider = Provider<void>((ref) {
  final appLinks = AppLinks();

  // `go` replaces the stack, so routing the launch link twice (some platforms
  // also emit it on the stream) just lands on the same page.
  void handle(Uri? uri) {
    final location = uri == null ? null : _locationFor(uri);
    if (location != null) ref.read(appRouterProvider).go(location);
  }

  final subscription = appLinks.uriLinkStream.listen(
    handle,
    onError: (Object e) => debugPrint('Deep link error: $e'),
  );
  ref.onDispose(subscription.cancel);

  unawaited(
    appLinks.getInitialLink().then(handle).catchError((Object e) => debugPrint('Initial deep link error: $e')),
  );
});

/// Maps a deep link to an in-app route, or null if it isn't one we handle.
String? _locationFor(Uri uri) {
  if (uri.scheme != 'ourhostel') return null;
  return switch (uri.host) {
    'setup-password' => AppRoutes.setupPasswordWithToken(uri.queryParameters['token'] ?? ''),
    _ => null,
  };
}
