import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ngobrolin_app/theme/app_colors.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final File? localFile;
  final String? name;
  final double radius;
  final double fontSize;
  final Color backgroundColor;
  final Color textColor;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.localFile,
    this.name,
    this.radius = 24,
    this.fontSize = 14,
    this.backgroundColor = AppColors.white,
    this.textColor = AppColors.primary,
  });

  // Helper to extract the initial of the name, returns null if the name is empty or null
  String? get _initial {
    final cleanName = name?.trim() ?? '';
    if (cleanName.isEmpty) return null;
    return cleanName[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final String? initialText = _initial;

    // Default widget if the image fails to load or does not exist
    final Widget fallbackAvatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: initialText != null
          ? Text(
              initialText,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            )
          : Icon(
              Icons
                  .image_outlined, // You can also change this to Icons.person_outline if preferred
              size: radius,
              color: textColor,
            ),
    );

    // 1. First priority: Local File
    if (localFile != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        backgroundImage: FileImage(localFile!),
      );
    }

    // 2. Second priority: If URL is empty or null, return fallback immediately
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return fallbackAvatar;
    }

    // 3. Third priority: Load image from URL
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: SizedBox(
          width: radius * 0.4,
          height: radius * 0.4,
          child: CircularProgressIndicator(strokeWidth: 2, color: textColor),
        ),
      ),
      errorWidget: (context, url, error) => fallbackAvatar,
    );
  }
}
