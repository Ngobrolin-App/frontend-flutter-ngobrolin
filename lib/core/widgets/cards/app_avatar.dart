import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ngobrolin_app/theme/app_colors.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final File? localFile; // Untuk menampung gambar dari file picker/kamera
  final String name;
  final double radius;
  final double fontSize;
  final Color backgroundColor;
  final Color textColor;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.localFile,
    required this.name,
    this.radius = 24,
    this.fontSize = 14,
    this.backgroundColor = AppColors.white,
    this.textColor = AppColors.primary,
  });

  // Helper untuk mengekstrak inisial nama
  String get _initial {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return '?';
    return cleanName[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final Widget fallbackAvatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: Text(
        _initial,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );

    if (localFile != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        backgroundImage: FileImage(localFile!),
      );
    }

    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return fallbackAvatar;
    }

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
