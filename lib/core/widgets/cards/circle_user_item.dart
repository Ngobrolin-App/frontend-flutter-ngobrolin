import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_colors.dart';
import '../../models/user_model.dart';

class CircleUserItem extends StatelessWidget {
  final UserModel user;
  final double radius;

  const CircleUserItem({super.key, required this.user, this.radius = 32});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.lightGrey,
          backgroundImage: user.avatarUrl != null
              ? CachedNetworkImageProvider(user.avatarUrl!)
              : null,
          child: user.avatarUrl == null
              ? Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: radius * 0.7,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: radius * 2.5,
          child: Text(
            user.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.text,
            ),
          ),
        ),
      ],
    );
  }
}
