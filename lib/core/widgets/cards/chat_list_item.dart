import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:ngobrolin_app/core/models/chat_list_item_model.dart';
import '../../../theme/app_colors.dart';
import '../../localization/app_localizations.dart';
import 'dart:developer' as developer;

class ChatListItem extends StatelessWidget {
  final ChatListItemModel chat;
  final VoidCallback onTap;

  const ChatListItem({Key? key, required this.chat, required this.onTap})
    : super(key: key);

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
                      if ((chat.unreadCount ?? 0) > 0) ...[
                        const SizedBox(width: 8),
                        _buildUnreadBadge(),
                      ],
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
    final String? imageUrl = (chat.type == 'private')
        ? chat.privatePartnerUser?.avatarUrl
        : chat.groupImage;

    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;

    developer.log(
      'ChatListItem - hasImage: $hasImage - imageUrl: $imageUrl',
      name: 'ChatListItem',
    );

    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.lightGrey,
      // Jika ada gambar, gunakan ImageProvider, jika tidak, null
      backgroundImage: hasImage ? CachedNetworkImageProvider(imageUrl) : null,
      // Jika tidak ada gambar, tampilkan inisial nama
      child: (!hasImage) ? _buildInitials() : null,
    );
  }

  Widget _buildInitials() {
    final name = (chat.type == 'private')
        ? chat.privatePartnerUser?.name
        : chat.name;

    final initial = (name != null && name.isNotEmpty)
        ? name[0].toUpperCase()
        : '?';

    return Text(
      initial,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final name = (chat.type == 'private')
        ? chat.privatePartnerUser?.name ?? 'Unknown'
        : chat.name ?? 'Group';

    final rawTimestamp = chat.lastMessage?.createdAt ?? chat.joinedAt;

    DateTime dateTime;

    if (rawTimestamp is DateTime) {
      dateTime = rawTimestamp;
    } else {
      // Fallback jika data null atau tipe data tidak dikenal
      dateTime = DateTime.now();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        Text(
          context.loc.formatTime(
            dateTime,
          ), // Sekarang dateTime pasti objek DateTime
          style: const TextStyle(fontSize: 12, color: AppColors.timestamp),
        ),
      ],
    );
  }

  Widget _buildLastMessage(BuildContext context) {
    final unreadCount = chat.unreadCount ?? 0;
    final textStyle = TextStyle(
      fontSize: 14,
      color: unreadCount > 0 ? AppColors.text : AppColors.timestamp,
      fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
    );

    Widget icon;
    String text;

    final lastMessageType = chat.lastMessage?.type;
    final lastMessageContent = chat.lastMessage?.content;

    switch (lastMessageType) {
      case 'image':
        icon = Iconify(
          MaterialSymbols.image,
          size: 18,
          color: AppColors.timestamp,
        );
        text = context.tr('image');
        break;
      case 'file':
        icon = Iconify(
          MaterialSymbols.file_copy_rounded,
          size: 18,
          color: AppColors.timestamp,
        );
        text = context.tr('file');
        break;
      default:
        return Text(
          lastMessageContent ?? '',
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
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        ),
      ],
    );
  }

  Widget _buildUnreadBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: const BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
      ),
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      child: Center(
        child: Text(
          chat.unreadCount.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
