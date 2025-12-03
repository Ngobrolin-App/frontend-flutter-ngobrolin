import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:ngobrolin_app/core/models/chat.dart';
import '../../../theme/app_colors.dart';
import '../../localization/app_localizations.dart';

class ChatListItem extends StatelessWidget {
  final Chat chat;
  final VoidCallback onTap;

  const ChatListItem({Key? key, required this.chat, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            _buildAvatar(),
            const SizedBox(width: 12),
            // Chat info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(child: _buildLastMessage(context)),
                      if (chat.unreadCount > 0) ...[const SizedBox(width: 8), _buildUnreadBadge()],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.lightGrey,
      backgroundImage: chat.avatarUrl != null ? CachedNetworkImageProvider(chat.avatarUrl!) : null,
      child: chat.avatarUrl == null
          ? Text(
              chat.name.isNotEmpty ? chat.name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          chat.name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text),
        ),
        Text(
          context.loc.formatTime(chat.timestamp),
          style: const TextStyle(fontSize: 12, color: AppColors.timestamp),
        ),
      ],
    );
  }

  Widget _buildLastMessage(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: 14,
      color: chat.unreadCount > 0 ? AppColors.text : AppColors.timestamp,
      fontWeight: chat.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
    );

    Widget icon;
    String text;

    switch (chat.lastMessageType) {
      case 'image':
        icon = Iconify(MaterialSymbols.image, size: 18, color: AppColors.timestamp);
        text = context.tr('image');
        break;
      case 'file':
        icon = Iconify(MaterialSymbols.file_copy_rounded, size: 18, color: AppColors.timestamp);
        text = context.tr('file');
        break;
      default:
        return Text(
          chat.lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textStyle,
        );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 6),
        Flexible(
          child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: textStyle),
        ),
      ],
    );
  }

  Widget _buildUnreadBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      child: Center(
        child: Text(
          chat.unreadCount.toString(),
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
