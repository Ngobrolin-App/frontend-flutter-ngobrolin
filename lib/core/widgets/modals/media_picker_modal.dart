import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ic.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:ngobrolin_app/core/enums/general_enums.dart';
import 'package:ngobrolin_app/core/localization/app_localizations.dart';
import 'package:ngobrolin_app/core/widgets/modals/app_bottom_sheet.dart';
import 'package:ngobrolin_app/theme/app_colors.dart';
// Import AppBottomSheet di sini

class MediaPickerModal {
  static Widget _buildOptionRow({
    required Widget icon,
    required String title,
    required VoidCallback? onTap,
    bool isEnabled = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: isEnabled
                    ? null
                    : const TextStyle(color: AppColors.deactiveButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<MediaSource?> showMediaPickerBottomSheet(
    BuildContext context, {
    bool showFileOption = false,
  }) async {
    return AppBottomSheet.show<MediaSource>(
      context: context,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildOptionRow(
              icon: const Icon(
                Icons.camera_alt_rounded,
                color: AppColors.primary,
              ),
              title: context.tr(MediaSource.camera.getTranslateKey),
              onTap: () => Navigator.pop(context, MediaSource.camera),
            ),
            const SizedBox(height: 8),
            _buildOptionRow(
              icon: const Icon(Icons.image, color: AppColors.primary),
              title: context.tr(MediaSource.gallery.getTranslateKey),
              onTap: () => Navigator.pop(context, MediaSource.gallery),
            ),
            if (showFileOption) ...[
              const SizedBox(height: 8),
              _buildOptionRow(
                icon: const Icon(
                  Icons.insert_drive_file,
                  color: AppColors.primary,
                ),
                title: context.tr(MediaSource.file.getTranslateKey),
                onTap: () => Navigator.pop(context, MediaSource.file),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Future<ProfileTapOption?> showProfileTapOptionModal(
    BuildContext context, {
    bool viewProfileImageEnabled = false,
  }) async {
    return AppBottomSheet.show<ProfileTapOption>(
      context: context,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildOptionRow(
              icon: Iconify(
                Ic.twotone_open_with,
                color: viewProfileImageEnabled
                    ? AppColors.primary
                    : AppColors.deactiveButton,
              ),
              title: context.tr(
                ProfileTapOption.viewProfileImage.getTranslateKey,
              ),
              onTap: viewProfileImageEnabled
                  ? () => Navigator.pop(
                      context,
                      ProfileTapOption.viewProfileImage,
                    )
                  : null,
              isEnabled: viewProfileImageEnabled,
            ),
            const SizedBox(height: 8),
            _buildOptionRow(
              icon: const Iconify(Mdi.image_edit, color: AppColors.primary),
              title: context.tr(
                ProfileTapOption.changeProfileImage.getTranslateKey,
              ),
              onTap: () =>
                  Navigator.pop(context, ProfileTapOption.changeProfileImage),
            ),
          ],
        ),
      ),
    );
  }
}
