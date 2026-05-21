import 'package:ngobrolin_app/core/models/deeplink/deeplink_data.dart';
import 'package:ngobrolin_app/routes/app_routes.dart';

import 'deeplink_routes.dart';

class DeeplinkHandler {
  static DeeplinkData? parse(Uri uri) {
    final host = uri.host;

    switch (host) {
      case DeeplinkRoutes.chat:
        final userId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;

        if (userId == null || userId.isEmpty) {
          return null;
        }

        return DeeplinkData(route: AppRoutes.chat, arguments: {'userId': userId});

      case DeeplinkRoutes.resetPassword:
        final token = uri.queryParameters['token'];

        if (token == null || token.isEmpty) {
          return null;
        }

        return DeeplinkData(route: AppRoutes.resetPassword, arguments: {'token': token});

      default:
        return null;
    }
  }
}
