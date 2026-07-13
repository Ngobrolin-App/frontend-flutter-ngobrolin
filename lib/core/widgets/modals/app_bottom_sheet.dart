import 'package:flutter/material.dart';
import 'package:ngobrolin_app/theme/app_colors.dart';

class AppBottomSheet {
  /// Menampilkan kerangka Bottom Sheet standar aplikasi Ngobrolin
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor:
          Colors.transparent, // Penting agar border radius terlihat
      builder: (context) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Drag Handle Bawaan
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  height: 5,
                  width: 48,
                  decoration: BoxDecoration(
                    color: AppColors.grey.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              // 2. Konten Dinamis yang di-inject dari luar
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
