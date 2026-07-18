import 'package:flutter/material.dart';
import 'package:ngobrolin_app/core/localization/app_localizations.dart';
import 'package:ngobrolin_app/core/services/app_permission_service.dart';
import 'package:ngobrolin_app/theme/app_colors.dart';

class PermissionUtils {
  static Future<bool> _showPrePermissionDialog({
    required BuildContext context,
    required String titleKey,
    required String descKey,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr(titleKey)),
        content: Text(dialogContext.tr(descKey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.tr('later')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              dialogContext.tr('enable'),
              style: const TextStyle(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  static Future<bool> checkAndRequestNotification(BuildContext context) async {
    if (await AppPermissionService.shouldShowNotificationDialog()) {
      if (!context.mounted) return false;

      final proceed = await _showPrePermissionDialog(
        context: context,
        titleKey: 'notification_permission_request',
        descKey: 'notification_permission_request_desc',
      );

      if (proceed) {
        await AppPermissionService.requestNotification();
        return true;
      }
      return false;
    }

    await AppPermissionService.requestNotification();
    return true;
  }

  static Future<bool> checkAndRequestCamera(BuildContext context) async {
    if (await AppPermissionService.shouldShowCameraDialog()) {
      if (!context.mounted) return false;

      final proceed = await _showPrePermissionDialog(
        context: context,
        titleKey: 'camera_permission_request',
        descKey: 'camera_permission_request_desc',
      );

      if (proceed) {
        return await AppPermissionService.requestCamera();
      }
      return false;
    }
    return await AppPermissionService.requestCamera();
  }

  static Future<bool> checkAndRequestMedia(BuildContext context) async {
    if (await AppPermissionService.shouldShowMediaDialog()) {
      if (!context.mounted) return false;

      final proceed = await _showPrePermissionDialog(
        context: context,
        titleKey: 'media_permission_request',
        descKey: 'media_permission_request_desc',
      );

      if (proceed) {
        return await AppPermissionService.requestMedia();
      }
      return false;
    }
    return await AppPermissionService.requestMedia();
  }
}
