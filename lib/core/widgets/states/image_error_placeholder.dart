import 'package:flutter/material.dart';
import 'package:ngobrolin_app/core/localization/app_localizations.dart';
import 'package:ngobrolin_app/theme/app_colors.dart';

class ImageErrorPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final double iconSize;
  final bool showText;
  final String? errorMessage;
  final BoxShape shape;
  final BorderRadiusGeometry? borderRadius;

  const ImageErrorPlaceholder({
    super.key,
    this.width,
    this.height,
    this.iconSize = 32,
    this.showText = true,
    this.errorMessage,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        // Menggunakan warna dari AppColors
        color: AppColors.lightGrey,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle
            ? (borderRadius ?? BorderRadius.circular(12))
            : null,
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.broken_image_rounded,
            size: iconSize,
            color: AppColors.grey, // Menggunakan warna dari AppColors
          ),
          if (showText) ...[
            const SizedBox(height: 6),
            Text(
              errorMessage ?? context.tr('failed_to_load_image'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.text, // Menggunakan warna dari AppColors
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
