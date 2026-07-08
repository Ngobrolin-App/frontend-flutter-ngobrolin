import 'package:flutter/material.dart';
import 'package:ngobrolin_app/core/enums/general_enums.dart';
import 'package:ngobrolin_app/core/localization/app_localizations.dart';
import 'package:ngobrolin_app/theme/app_colors.dart';

class MediaPickerModal {
  /// Shows a bottom sheet to select a media source.
  /// Set [showFileOption] to true if you want to include the document/file picker (e.g., in chat).
  static Future<MediaSource?> showPickerBottomSheet(
    BuildContext context, {
    bool showFileOption = false,
  }) async {
    return showModalBottomSheet<MediaSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // OPTION 1: CAMERA
              GestureDetector(
                onTap: () => Navigator.pop(ctx, MediaSource.camera),
                child: Row(
                  children: [
                    const Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(context.tr('take_photo'))),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // OPTION 2: GALLERY
              GestureDetector(
                onTap: () => Navigator.pop(ctx, MediaSource.gallery),
                child: Row(
                  children: [
                    const Icon(Icons.image, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text(context.tr('choose_image'))),
                  ],
                ),
              ),

              // OPTION 3: FILE (Conditional)
              if (showFileOption) ...[
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx, MediaSource.file),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.insert_drive_file,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(context.tr('choose_file'))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
