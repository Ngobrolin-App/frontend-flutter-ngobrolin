import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class AppPermissionService {
  // ==========================================
  // --- NOTIFICATION ---
  // ==========================================
  static Future<bool> shouldShowNotificationDialog() async {
    final status = await Permission.notification.status;
    return status.isDenied;
  }

  static Future<void> requestNotification() async {
    await Permission.notification.request();
  }

  // ==========================================
  // --- CAMERA ---
  // ==========================================

  /// Check whether it is necessary to display the pre-permission dialog for the camera.
  static Future<bool> shouldShowCameraDialog() async {
    final status = await Permission.camera.status;
    return status.isDenied;
  }

  static Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      openAppSettings();
      return false;
    }
    return status.isGranted;
  }

  // ==========================================
  // --- FILES, PHOTOS & VIDEOS ---
  // ==========================================

  /// Check whether it is necessary to display the pre-permission dialog for the media.
  static Future<bool> shouldShowMediaDialog() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        // Check photo and video status for Android 13+
        final photoStatus = await Permission.photos.status;
        final videoStatus = await Permission.videos.status;
        // If one is not allowed, display a dialog.
        return photoStatus.isDenied || videoStatus.isDenied;
      } else {
        // Check storage status for Android 12 and below
        final status = await Permission.storage.status;
        return status.isDenied;
      }
    } else {
      // Check gallery status for iOS
      final status = await Permission.photos.status;
      return status.isDenied;
    }
  }

  static Future<bool> requestMedia() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        final statuses = await [Permission.photos, Permission.videos].request();
        return statuses[Permission.photos]!.isGranted &&
            statuses[Permission.videos]!.isGranted;
      } else {
        final status = await Permission.storage.request();
        if (status.isPermanentlyDenied) {
          openAppSettings();
          return false;
        }
        return status.isGranted;
      }
    } else {
      final status = await Permission.photos.request();
      if (status.isPermanentlyDenied) {
        openAppSettings();
        return false;
      }
      return status.isGranted;
    }
  }
}
