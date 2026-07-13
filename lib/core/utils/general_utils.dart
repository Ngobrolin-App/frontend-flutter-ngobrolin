import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:ngobrolin_app/core/localization/app_localizations.dart';
import 'package:ngobrolin_app/core/models/message_model.dart';
import 'package:ngobrolin_app/core/repositories/settings_repository.dart';
import 'package:ngobrolin_app/theme/app_colors.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';

class GeneralUtils {
  static Future<void> downloadAndOpen(BuildContext context, String url) async {
    final dir = await getTemporaryDirectory();
    final segs = Uri.parse(url).pathSegments;
    final name = segs.isNotEmpty
        ? segs.last
        : 'file_${DateTime.now().millisecondsSinceEpoch}';
    final path = '${dir.path}/$name';
    await Dio().download(url, path);
    await OpenFile.open(path);
  }

  static Future<Map<String, dynamic>> getFileDetails(File file) async {
    return {
      'path': file.path,
      'size': await file.length(),
      'mimeType': lookupMimeType(file.path) ?? 'application/octet-stream',
      'fileName': path.basename(file.path),
    };
  }

  static Future<File?> cropImage({
    required String sourcePath,
    required String title,
    bool isSquare = false,
  }) async {
    final presets = isSquare
        ? [CropAspectRatioPreset.square]
        : [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ];

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: title,
            toolbarColor: AppColors.black,
            toolbarWidgetColor: AppColors.white,
            activeControlsWidgetColor: AppColors.accent,
            initAspectRatio: isSquare
                ? CropAspectRatioPreset.square
                : CropAspectRatioPreset.original,
            lockAspectRatio: isSquare,
            hideBottomControls: false,
            aspectRatioPresets: presets,
          ),
          IOSUiSettings(
            title: title,
            doneButtonTitle: 'Selesai',
            cancelButtonTitle: 'Batal',
            aspectRatioLockEnabled: isSquare,
            resetAspectRatioEnabled: !isSquare,
            aspectRatioPresets: presets,
          ),
        ],
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }
    } catch (e) {
      debugPrint('GeneralUtils - cropImage error: $e');
    }
    return null;
  }

  static String getChatDateHeader(
    DateTime messageDate,
    BuildContext context, {
    String localeCode = 'en',
    bool useNumericFormat = false,
    bool showTodayTime = false,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Normalisasi jam/menit/detik dari messageDate untuk perbandingan yang akurat
    final normalizedMessageDate = DateTime(
      messageDate.year,
      messageDate.month,
      messageDate.day,
    );

    if (normalizedMessageDate == today) {
      // Jika showTodayTime true, kembalikan jam dan menit
      if (showTodayTime) {
        // Gunakan 'HH:mm' untuk format 24 jam (misal: 15:30)
        // Gunakan 'hh:mm a' jika ingin format 12 jam (misal: 03:30 PM)
        return DateFormat('HH:mm', localeCode).format(messageDate);
      }
      return context.tr('today');
    } else if (normalizedMessageDate == yesterday) {
      return context.tr('yesterday');
    } else if (now.difference(normalizedMessageDate).inDays < 7) {
      // Menampilkan nama hari (misal: "Senin" jika locale 'id', "Monday" jika 'en')
      return DateFormat('EEEE', localeCode).format(messageDate);
    } else {
      // Menampilkan tanggal penuh sesuai opsi yang dipilih
      if (useNumericFormat) {
        // Hasil: 29/06/2026
        return DateFormat('dd/MM/yyyy', localeCode).format(messageDate);
      } else {
        // Hasil: 29 Juni 2026 (jika locale 'id') atau 29 June 2026 (jika locale 'en')
        return DateFormat('d MMMM y', localeCode).format(messageDate);
      }
    }
  }

  static String getSystemMessageText(
    MessageModel message,
    BuildContext context,
  ) {
    final systemMetadata = message.systemMetadata ?? {};
    final systemEventType = message.systemEventType;

    // Ekstraksi nilai seragam berdasarkan Kontrak Blueprint
    final String actorName = systemMetadata['actorName'] ?? 'Someone';
    final String targetName = systemMetadata['targetName'] ?? 'someone';
    final String groupName = systemMetadata['groupName'] ?? 'Group';
    final String groupDescription =
        systemMetadata['groupDescription'] ?? 'Group Description';

    switch (systemEventType) {
      case 'GROUP_CREATED':
        return context.tr(
          'system_msg_group_created',
          args: {'actorName': actorName, 'groupName': groupName},
        );

      case 'USER_ADDED':
        return context.tr(
          'system_msg_user_added',
          args: {'actorName': actorName, 'targetName': targetName},
        );

      case 'GROUP_IMAGE_CHANGED':
        return context.tr(
          'system_msg_image_changed',
          args: {'actorName': actorName},
        );

      case 'GROUP_NAME_CHANGED':
        return context.tr(
          'system_msg_name_changed',
          args: {'actorName': actorName, 'groupName': groupName},
        );

      case 'GROUP_DESCRIPTION_CHANGED':
        return context.tr(
          'system_msg_description_changed',
          args: {
            'actorName': actorName,
            'groupName': groupName,
            'groupDescription': groupDescription,
          },
        );

      case 'USER_REMOVED':
        return context.tr(
          'system_msg_user_removed',
          args: {'actorName': actorName, 'targetName': targetName},
        );

      case 'USER_LEFT':
        return context.tr(
          'system_msg_user_left',
          args: {'actorName': actorName},
        );

      default:
        // Fallback: Jika ada event baru dari backend namun aplikasi versi user belum di-update
        return message.content ?? '';
    }
  }
}
