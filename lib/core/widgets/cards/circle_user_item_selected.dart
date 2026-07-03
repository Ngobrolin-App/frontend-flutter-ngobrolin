import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../models/user_model.dart';
import 'circle_user_item.dart';

class CircleUserItemSelected extends StatelessWidget {
  final UserModel user;
  final VoidCallback onRemove;
  final double radius;

  const CircleUserItemSelected({
    super.key,
    required this.user,
    required this.onRemove,
    this.radius = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Menggunakan komponen CircleUserItem yang sudah kita buat
        Padding(
          padding: const EdgeInsets.all(
            4,
          ), // Memberi sedikit ruang untuk tombol X
          child: CircleUserItem(user: user, radius: radius),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: AppColors.primary,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
