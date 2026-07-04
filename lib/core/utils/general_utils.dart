import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:ngobrolin_app/theme/app_colors.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

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
}
