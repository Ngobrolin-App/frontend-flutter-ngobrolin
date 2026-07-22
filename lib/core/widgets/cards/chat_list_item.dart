import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:ngobrolin_app/core/enums/general_enums.dart';
import 'package:ngobrolin_app/core/models/chat_list_item_model.dart';
import 'package:ngobrolin_app/core/utils/chat_utils.dart';
import 'package:ngobrolin_app/core/viewmodels/auth/auth_view_model.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../localization/app_localizations.dart';

class ChatListItem extends StatelessWidget {
  final ChatListItemModel chat;
  final VoidCallback onTap;
  final ConversationType? type;
  final String? languageCode;

  const ChatListItem({
    super.key,
    required this.chat,
    required this.onTap,
    this.languageCode,
    this.type,
  });

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
    final String? imageUrl = (chat.type == ConversationType.private.name)
        ? chat.privatePartnerUser?.avatarUrl
        : chat.groupImage;

    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;

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
    final name = (chat.type == ConversationType.private.name)
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
    final name = (chat.type == ConversationType.private.name)
        ? chat.privatePartnerUser?.name ?? 'Unknown'
        : chat.name ?? 'Group';

    final rawTimestamp = chat.lastMessage?.createdAt ?? chat.joinedAt;

    DateTime? dateTime;

    if (rawTimestamp is DateTime) {
      dateTime = rawTimestamp;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ),
        if (dateTime != null)
          Text(
            ChatUtils.getChatDateHeader(
              dateTime,
              context,
              showTodayTime: true,
              useNumericFormat: true,
              localeCode: languageCode ?? 'en',
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
    final typingTextStyle = TextStyle(
      fontSize: 14,
      color: AppColors.accent,
      fontWeight: FontWeight.w700,
      fontStyle: FontStyle.italic,
    );

    final lastMessage = chat.lastMessage;
    final bool lastMessageIsReadStatus = chat.lastMessage?.isRead ?? false;
    final lastMessageType = lastMessage?.type;
    final senderName = lastMessage?.sender?.name;
    final hasSenderName = senderName?.isNotEmpty ?? false;

    Widget? icon;
    String text = lastMessage?.content ?? '';

    switch (lastMessage?.type) {
      case 'image':
        icon = const Iconify(
          MaterialSymbols.image,
          size: 18,
          color: AppColors.timestamp,
        );
        text = lastMessage?.content ?? context.tr('image');
        break;

      case 'file':
        icon = const Iconify(
          MaterialSymbols.file_copy_rounded,
          size: 18,
          color: AppColors.timestamp,
        );
        text = lastMessage?.content ?? context.tr('file');
        break;

      case 'system':
        if (lastMessage != null) {
          text = ChatUtils.getSystemMessageText(lastMessage, context);
        }
        break;
    }

    return Selector<AuthViewModel, (String?,)>(
      selector: (_, vm) => (vm.currentUserId,),
      builder: (context, data, _) {
        final currentUserId = data.$1;
        final bool isSendByMe = lastMessage?.senderId == currentUserId;
        return Row(
          children: (chat.isTyping ?? false)
              ? [
                  Expanded(
                    child: Text(
                      context.tr(
                        'user_typing',
                        args: {'actorName': chat.typingUserName ?? 'Someone'},
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typingTextStyle,
                    ),
                  ),
                ]
              : [
                  if (isSendByMe) ...[
                    Iconify(
                      lastMessageIsReadStatus
                          ? MaterialSymbols.done_all_rounded
                          : MaterialSymbols.done_rounded,
                      size: 14,
                      color: lastMessageIsReadStatus
                          ? AppColors.messageRead
                          : AppColors.timestamp,
                    ),
                    SizedBox(width: 2),
                  ],
                  Expanded(
                    child: Row(
                      children: [
                        if (!isSendByMe &&
                            hasSenderName &&
                            (type == ConversationType.group) &&
                            lastMessageType != MessageType.system.name)
                          Text(
                            '$senderName: ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textStyle,
                          ),
                        if (icon != null) ...[icon, const SizedBox(width: 4)],
                        Expanded(
                          child: Text(
                            text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
        );
      },
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
            color: AppColors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
