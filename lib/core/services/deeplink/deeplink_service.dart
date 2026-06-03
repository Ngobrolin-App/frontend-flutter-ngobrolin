import 'dart:async';

import 'package:app_links/app_links.dart';

import '../../../bootstrap.dart';
import 'deeplink_handler.dart';

class DeeplinkService {
  final AppLinks _appLinks = AppLinks();

  StreamSubscription? _sub;

  Future<void> init() async {
    // APP CLOSED
    final initialUri = await _appLinks.getInitialLink();

    if (initialUri != null) {
      _handleUri(initialUri);
    }

    // APP OPEN
    _sub = _appLinks.uriLinkStream.listen((uri) {
      _handleUri(uri);
    });
  }

  void handleDeepLink(String link) {
    final uri = Uri.parse(link);

    _handleUri(uri);
  }

  void _handleUri(Uri uri) {
    final deeplink = DeeplinkHandler.parse(uri);

    if (deeplink == null) {
      return;
    }

    navigatorKey.currentState?.pushNamed(deeplink.route, arguments: deeplink.arguments);
  }

  void dispose() {
    _sub?.cancel();
  }
}
