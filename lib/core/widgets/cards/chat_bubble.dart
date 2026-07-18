// ignore_for_file: unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ngobrolin_app/core/enums/general_enums.dart';
import 'package:ngobrolin_app/core/utils/media_utils.dart';
import 'package:ngobrolin_app/core/widgets/cards/reply_message.dart';
import 'package:ngobrolin_app/core/widgets/states/image_error_placeholder.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:iconify_flutter/icons/ion.dart';
import 'package:ngobrolin_app/core/viewmodels/chat/chat_view_model.dart';
import '../../../theme/app_colors.dart';
import '../../localization/app_localizations.dart';
import '../../models/message_model.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final ConversationType? conversationType;
  final bool isLongPressOptionEnabled;
  final bool isMe;
  final bool showSenderName;
  final Function(String)? onReplyTap;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showSenderName = false,
    this.conversationType,
    this.onReplyTap,
    this.isLongPressOptionEnabled = true,
  });

  String _extractFileName(String? url, String fallback) {
    if (url == null || url.isEmpty) return fallback;
    final uri = Uri.tryParse(url);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    return fallback;
  }

  void _showContextMenu({
    required BuildContext context,
    required Offset position,
    bool showDownloadAndOpen = false,
  }) async {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final result = await showMenu(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.white,
      elevation: 8,
      items: <PopupMenuEntry<String>>[
        PopupMenuItem(
          value: 'reply',
          child: Row(
            children: [
              Iconify(Mdi.reply, size: 20, color: AppColors.primary),
              SizedBox(width: 12),
              Text(context.tr('reply')),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'copy',
          child: Row(
            children: [
              Iconify(Mdi.content_copy, size: 20, color: AppColors.primary),
              SizedBox(width: 12),
              Text(context.tr('copy')),
            ],
          ),
        ),
        if (showDownloadAndOpen)
          PopupMenuItem(
            value: 'download',
            child: Row(
              children: [
                Iconify(
                  MaterialSymbols.download_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                SizedBox(width: 12),
                Text(context.tr('download')),
              ],
            ),
          ),
        // PopupMenuItem(
        //   value: 'forward',
        //   child: Row(
        //     children: [
        //       Iconify(Ion.forward, size: 20, color: AppColors.primary),
        //       SizedBox(width: 12),
        //       Text(context.tr('forward')),
        //     ],
        //   ),
        // ),
        // const PopupMenuDivider(),
        // PopupMenuItem(
        //   value: 'unsend_message',
        //   child: Row(
        //     children: [
        //       Iconify(
        //         MaterialSymbols.delete_forever_outline_rounded,
        //         size: 20,
        //         color: AppColors.primary,
        //       ),
        //       SizedBox(width: 12),
        //       Text(context.tr('unsend_message')),
        //     ],
        //   ),
        // ),
      ],
    );

    if (result != null && context.mounted) {
      _handleMenuAction(result, context);
    }
  }

  void _handleMenuAction(String value, BuildContext context) {
    final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
    switch (value) {
      case 'reply':
        chatViewModel.setReplyingTo(message);
        break;
      case 'copy':
        Clipboard.setData(ClipboardData(text: message.content ?? ''));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('copied_to_clipboard')),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
          ),
        );
        break;
      case 'download':
        MediaUtils.downloadAndOpen(context, message.mediaUrl ?? '');
        break;
      case 'forward':
        break;
      case 'unsend_message':
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPressStart: isLongPressOptionEnabled
            ? (details) => _showContextMenu(
                context: context,
                position: details.globalPosition,
              )
            : null,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: isMe ? AppColors.chatBubbleUser : AppColors.chatBubbleOther,
            borderRadius: BorderRadius.circular(16).copyWith(
              bottomRight: isMe ? const Radius.circular(4) : null,
              bottomLeft: !isMe ? const Radius.circular(4) : null,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isMe &&
                    (conversationType == ConversationType.group) &&
                    showSenderName)
                  Align(
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 8,
                        left: 8,
                        right: 8,
                        bottom: (message.repliedMessage != null) ? 4 : 0,
                      ),
                      child: Text(
                        message.sender?.name ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.buttonText,
                        ),
                      ),
                    ),
                  ),

                if (message.repliedMessage != null) ...[
                  const SizedBox(height: 4),
                  _buildRepliedMessage(context),
                  const SizedBox(height: 4),
                ],
                if (message.forwardedFromMessageId != null)
                  _buildForwardedMark(context),

                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMainContent(context),
                      const SizedBox(height: 4),
                      _buildMessageMetadata(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- SUB-WIDGET BUILDERS ---

  Widget _buildRepliedMessage(BuildContext context) {
    return ReplyMessageWidget(
      message: message.repliedMessage!,
      onTap: () {
        if (message.repliedMessage!.id != null) {
          onReplyTap?.call(message.repliedMessage!.id);
        }
      },
    );
  }

  Widget _buildForwardedMark(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 2, bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Iconify(Ion.forward, size: 14, color: AppColors.timestamp),
          Text(
            context.tr('forwarded'),
            style: TextStyle(fontSize: 12, color: AppColors.timestamp),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    switch (message.type) {
      case 'image':
        return _buildImageMessage(context);
      case 'file':
        return _buildFileMessage(context);
      default:
        return _buildTextMessage(context);
    }
  }

  Widget _buildTextMessage(BuildContext context) {
    return Text(
      message.content ?? '',
      style: const TextStyle(fontSize: 16, color: AppColors.text),
    );
  }

  Widget _buildImageMessage(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    insetPadding: const EdgeInsets.all(16),
                    child: PhotoView(
                      imageProvider: NetworkImage(message.mediaUrl ?? ''),
                      initialScale: PhotoViewComputedScale.contained,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: ImageErrorPlaceholder(
                            width: double.infinity,
                            height: double.infinity,
                            iconSize: 48,
                            errorMessage: context.tr('failed_to_load_image'),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },

              onLongPressStart: isLongPressOptionEnabled
                  ? (details) => _showContextMenu(
                      context: context,
                      position: details.globalPosition,
                      showDownloadAndOpen: true,
                    )
                  : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: message.mediaUrl ?? '',
                  width: MediaQuery.of(context).size.width * 0.6,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => ImageErrorPlaceholder(
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: 160,
                    iconSize: 40,
                    errorMessage: context.tr('failed_to_load_image'),
                  ),
                ),
              ),
            ),

            if (message.content?.isNotEmpty ?? false) ...[
              const SizedBox(height: 4),
              _buildTextMessage(context), // Display caption below the image
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFileMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () =>
                MediaUtils.downloadAndOpen(context, message.mediaUrl ?? ''),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Iconify(
                  Mdi.file_document,
                  size: 24,
                  color: AppColors.text,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _extractFileName(
                      message.mediaFileName ?? '',
                      context.tr('file'),
                    ),
                    style: const TextStyle(fontSize: 16, color: AppColors.text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Iconify(
                  MaterialSymbols.open_in_new,
                  size: 20,
                  color: AppColors.accent,
                ),
              ],
            ),
          ),
          if (message.content?.isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            _buildTextMessage(context), // Display caption below the image
          ],
        ],
      ),
    );
  }

  Widget _buildMessageMetadata(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.loc.formatTime(message.createdAt),
          style: const TextStyle(fontSize: 12, color: AppColors.timestamp),
        ),
        if (isMe) ...[
          const SizedBox(width: 4),
          Iconify(
            message.isRead
                ? MaterialSymbols.done_all_rounded
                : MaterialSymbols.done_rounded,
            size: 14,
            color: message.isRead ? AppColors.messageRead : AppColors.timestamp,
          ),
        ],
      ],
    );
  }
}
