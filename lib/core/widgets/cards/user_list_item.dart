import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_colors.dart';

class UserListItem extends StatelessWidget {
  final String id;
  final String name;
  final String username;
  final String? avatarUrl;
  final VoidCallback onTap;
  final VoidCallback? onActionTap;
  final IconData? actionIcon;
  final Widget? actionWidget;
  final String? actionText;
  final bool isPrivate;

  const UserListItem({
    Key? key,
    required this.id,
    required this.name,
    required this.username,
    this.avatarUrl,
    required this.onTap,
    this.onActionTap,
    this.actionIcon,
    this.actionWidget,
    this.actionText,
    this.isPrivate = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.lightGrey,
              backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl!) : null,
              child: avatarUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@$username',
                    style: const TextStyle(fontSize: 14, color: AppColors.timestamp),
                  ),
                ],
              ),
            ),
            // Action button
            if (onActionTap != null &&
                (actionIcon != null || actionWidget != null || actionText != null) &&
                !isPrivate)
              InkWell(
                onTap: onActionTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (actionWidget != null) ...[
                        actionWidget!,
                        if (actionText != null) const SizedBox(width: 4),
                      ] else if (actionIcon != null) ...[
                        Icon(actionIcon, color: Colors.white, size: 16),
                        if (actionText != null) const SizedBox(width: 4),
                      ],
                      if (actionText != null)
                        Text(
                          actionText!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
