import 'package:ngobrolin_app/core/models/deeplink/deeplink_data.dart';
import 'package:ngobrolin_app/routes/app_routes.dart';

import 'deeplink_routes.dart';
import 'dart:developer' as developer;

class DeeplinkHandler {
  // Untuk FCM / Notification
  static DeeplinkData? parseFromNotification(Map<String, dynamic> data) {
    final screen = data['screen']; // Backend mengirim 'chat'

    switch (screen) {
      case DeeplinkRoutes.chat:
        return DeeplinkData(
          route: AppRoutes.chat,
          arguments: {
            'userId': data['userId'],
            'chatId': data['conversationId'],
            'name': data['name'],
            'avatarUrl': data['avatarUrl'],
          },
        );
      default:
        return null;
    }
  }

  static DeeplinkData? parseFromUri(Uri uri) {
    // developer.log(
    //   'DEBUG URI: host=${uri.host}, path=${uri.path}, query=${uri.query}',
    //   name: 'DeeplinkHandler',
    // );
    final String path = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.first
        : '';

    switch (path) {
      case DeeplinkRoutes.chat:
        final chatId = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
        if (chatId == null || chatId.isEmpty) {
          return null;
        }
        return DeeplinkData(
          route: AppRoutes.chat,
          arguments: {'chatId': chatId},
        );

      case DeeplinkRoutes.resetPassword:
        // Misal: ngobrolin://app/reset-password?token=abc
        final token = uri.queryParameters['token'];
        if (token == null || token.isEmpty) return null;
        return DeeplinkData(
          route: AppRoutes.resetPassword,
          arguments: {'token': token},
        );

      default:
        // developer.log(
        //   'DEBUG: Tidak ada rute yang cocok untuk path: $path',
        //   name: 'DeeplinkHandler',
        // );
        return null;
    }
  }
}
