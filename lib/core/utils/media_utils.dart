import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:ngobrolin_app/core/localization/app_localizations.dart';
import 'package:ngobrolin_app/core/utils/permission_utils.dart';
import 'package:ngobrolin_app/theme/app_colors.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'dart:developer' as developer;

class MediaUtils {
  static Future<Directory?> _getDirectory() async {
    if (Platform.isAndroid) {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final pathParts = externalDir.path.split('/');
        final androidIndex = pathParts.indexOf('Android');
        if (androidIndex != -1) {
          final rootPath = pathParts.sublist(0, androidIndex).join('/');
          return Directory('$rootPath/Download/Ngobrolin');
        }
        return Directory('/storage/emulated/0/Download/Ngobrolin');
      }
    } else if (Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    }
    return null;
  }

  static String _resolveFileName(String url, String? fileName) {
    if (fileName != null && fileName.isNotEmpty) return fileName;
    final segs = Uri.parse(url).pathSegments;
    if (segs.isNotEmpty && segs.last.contains('.')) {
      return segs.last;
    }
    return 'file_${DateTime.now().millisecondsSinceEpoch}';
  }

  static Future<String> getFilePath(String url, {String? fileName}) async {
    final dir = await _getDirectory();
    final finalFileName = _resolveFileName(url, fileName);
    return '${dir?.path ?? ''}/$finalFileName';
  }

  static Future<bool> isFileDownloaded(String url, {String? fileName}) async {
    final filePath = await getFilePath(url, fileName: fileName);
    return await File(filePath).exists();
  }

  static Future<void> openDownloadedFile(String url, {String? fileName}) async {
    final filePath = await getFilePath(url, fileName: fileName);
    if (await File(filePath).exists()) {
      await OpenFile.open(filePath);
    }
  }

  static Future<void> downloadAndOpen(
    BuildContext context,
    String url, {
    String? fileName,
    Function(double)? onProgress,
  }) async {
    try {
      if (!context.mounted) return;
      final isGranted = await PermissionUtils.checkAndRequestMedia(context);

      if (!isGranted) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('permission_denied')),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      final dir = await _getDirectory();
      if (dir != null && !await dir.exists()) {
        await dir.create(recursive: true);
      }

      final savePath = await getFilePath(url, fileName: fileName);

      if (await File(savePath).exists()) {
        await OpenFile.open(savePath);
        return;
      }

      await Dio().download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (onProgress != null) {
            if (total != -1) {
              onProgress(received / total);
            } else {
              onProgress(-1.0);
            }
          }
        },
      );

      await OpenFile.open(savePath);
    } catch (e) {
      developer.log('MediaUtils - downloadAndOpen error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('failed_to_download_or_open_file')),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
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
}
