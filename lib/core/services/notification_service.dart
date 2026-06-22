import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class NotificationService {
  static Future<bool> shouldShowPermissionDialog() async {
    // Cek status izin saat ini
    final status = await Permission.notification.status;

    // Tampilkan dialog hanya jika user belum pernah memutuskan (isDenied)
    // Jika sudah diizinkan (isGranted) atau ditolak permanen (isPermanentlyDenied), jangan tampilkan
    return status.isDenied;
  }

  static Future<void> requestPermission() async {
    await Permission.notification.request();
  }
}
