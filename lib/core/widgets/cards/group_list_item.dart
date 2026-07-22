import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ngobrolin_app/core/models/conversation_model.dart';
import '../../../theme/app_colors.dart';

class GroupListItem extends StatelessWidget {
  final ConversationModel group;
  final VoidCallback? onTap;
  final Widget? actionWidget;

  const GroupListItem({
    super.key,
    required this.group,
    this.onTap,
    this.actionWidget,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    group.name ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (group.groupDescription != null &&
                      (group.groupDescription?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 2),
                    Text(
                      group.groupDescription ?? '',
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.text.withOpacity(0.7),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (actionWidget != null) actionWidget!,
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.lightGrey,
      backgroundImage: group.groupImage != null
          ? CachedNetworkImageProvider(group.groupImage!)
          : null,
      child: group.groupImage == null
          ? Text(
              (group.name?.isNotEmpty ?? false)
                  ? group.name![0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            )
          : null,
    );
  }
}
