import 'package:flutter/material.dart';
import 'package:ngobrolin_app/theme/app_colors.dart';
// Kalau mau pakai Iconify (sesuaikan kalau lu milih pakai Icons material biasa)
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';

class BlockedBadge extends StatelessWidget {
  final String message;

  const BlockedBadge({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        // Padding dibikin sedikit lebih lega
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          // Background pakai warna warning tapi dibikin transparan (soft)
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          // Tambahan border tipis biar lebih tegas
          border: Border.all(
            color: AppColors.warning.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Biar Row menyesuaikan lebar konten
          children: [
            // Ikon gembok atau blokir
            Iconify(
              Mdi.block_helper, // Atau bisa pakai icon material: Icon(Icons.block, size: 16, color: AppColors.warning)
              color: AppColors.warning,
              size: 16,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                textAlign: TextAlign.center,
                maxLines: 3,
                style: const TextStyle(
                  fontSize: 12,
                  // Font dibikin semi-bold biar pesannya lebih "kuat"
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
