import 'dart:async';

import 'package:app_links/app_links.dart';

import '../../../bootstrap.dart';
import 'deeplink_handler.dart';
import 'dart:developer' as developer;

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

  void handleNotification(Map<String, dynamic> data) {
    final deeplink = DeeplinkHandler.parseFromNotification(data);
    if (deeplink != null) {
      navigatorKey.currentState?.pushNamed(
        deeplink.route,
        arguments: deeplink.arguments,
      );
    }
  }

  void handleDeepLink(String link) {
    final uri = Uri.parse(link);

    _handleUri(uri);
  }

  void _handleUri(Uri uri) {
    if (uri.pathSegments.isEmpty) return;

    // developer.log(
    //   'DeeplinkService - _handleUri - uri: $uri',
    //   name: 'DeeplinkService',
    // );
    final deeplink = DeeplinkHandler.parseFromUri(uri);

    if (deeplink == null) {
      return;
    }

    // developer.log(
    //   'DeeplinkService - _handleUri - deeplinkdata: $deeplink - deeplink.route: ${deeplink.route} - deeplink.arguments: ${deeplink.arguments}',
    //   name: 'DeeplinkService',
    // );

    navigatorKey.currentState?.pushNamed(
      deeplink.route,
      arguments: deeplink.arguments,
    );
  }

  void dispose() {
    _sub?.cancel();
  }
}
