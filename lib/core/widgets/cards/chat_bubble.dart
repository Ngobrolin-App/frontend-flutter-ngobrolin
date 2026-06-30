// ignore_for_file: unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';

import 'package:ngobrolin_app/core/utils/general_utils.dart';
import 'package:ngobrolin_app/core/viewmodels/chat/chat_view_model.dart';
import '../../../theme/app_colors.dart';
import '../../localization/app_localizations.dart';
import '../../models/message_model.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final Function(String)? onReplyTap;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onReplyTap,
  });

  String _extractFileName(String? url, String fallback) {
    if (url == null || url.isEmpty) return fallback;
    final uri = Uri.tryParse(url);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    return fallback;
  }

  void _showContextMenu(BuildContext context, Offset position) async {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final result = await showMenu(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      elevation: 8,
      items: [
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
      ],
    );

    if (result != null && context.mounted) {
      _handleMenuAction(result, context);
    }
  }

  void _handleMenuAction(String value, BuildContext context) {
    final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
    switch (value) {
      case 'copy':
        Clipboard.setData(ClipboardData(text: message.content));
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
      case 'reply':
        chatViewModel.setReplyingTo(message);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPressStart: (details) =>
            _showContextMenu(context, details.globalPosition),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? AppColors.chatBubbleUser : AppColors.chatBubbleOther,
            borderRadius: BorderRadius.circular(16).copyWith(
              bottomRight: isMe ? const Radius.circular(4) : null,
              bottomLeft: !isMe ? const Radius.circular(4) : null,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          // Menggunakan IntrinsicWidth agar lebar bubble membungkus konten secara pas
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.repliedMessage != null)
                  _buildRepliedMessage(context),
                if (message.repliedMessage != null) const SizedBox(height: 4),
                _buildMainContent(context),
                const SizedBox(height: 6),
                _buildMessageMetadata(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- SUB-WIDGET BUILDERS ---

  Widget _buildRepliedMessage(BuildContext context) {
    final replied = message.repliedMessage!;
    final isImage = replied.type == 'image';

    return GestureDetector(
      onTap: () {
        if (replied.id != null) {
          onReplyTap?.call(replied.id);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.lightGrey.withOpacity(0.5),
          border: const Border(
            left: BorderSide(color: AppColors.primary, width: 4),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      replied.sender?.name ?? '-',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _buildRepliedPreviewText(context, replied),
                  ],
                ),
              ),
            ),
            if (isImage)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                child: CachedNetworkImage(
                  imageUrl: replied.content,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepliedPreviewText(BuildContext context, MessageModel replied) {
    switch (replied.type) {
      case 'file':
        return Row(
          children: [
            const Iconify(
              Mdi.file_document_outline,
              size: 18,
              color: AppColors.text,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                _extractFileName(replied.content, context.tr('file')),
                style: const TextStyle(fontSize: 12, color: AppColors.text),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      case 'image':
        return Row(
          children: [
            const Iconify(
              MaterialSymbols.image_outline_rounded,
              size: 18,
              color: AppColors.text,
            ),
            const SizedBox(width: 4),
            Text(
              context.tr('image'),
              style: const TextStyle(fontSize: 12, color: AppColors.text),
            ),
          ],
        );
      default:
        return Text(
          replied.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppColors.text),
        );
    }
  }

  Widget _buildMainContent(BuildContext context) {
    switch (message.type) {
      case 'image':
        return _buildImageMessage(context);
      case 'file':
        return _buildFileMessage(context);
      default:
        return Text(
          message.content,
          style: const TextStyle(fontSize: 16, color: AppColors.text),
        );
    }
  }

  Widget _buildImageMessage(BuildContext context) {
    return Align(
      alignment: Alignment
          .centerLeft, // Mencegah gambar terdistorsi jika bubble melebar karena reply teks panjang
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => Dialog(
                insetPadding: const EdgeInsets.all(16),
                child: PhotoView(
                  imageProvider: NetworkImage(message.content),
                  initialScale: PhotoViewComputedScale.contained,
                ),
              ),
            );
          },
          onLongPress: () =>
              GeneralUtils.downloadAndOpen(context, message.content),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: message.content,
              width: MediaQuery.of(context).size.width * 0.6,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () => GeneralUtils.downloadAndOpen(context, message.content),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Iconify(Mdi.file_document, size: 24, color: AppColors.text),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _extractFileName(message.content, context.tr('file')),
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
    );
  }

  Widget _buildMessageMetadata(BuildContext context) {
    // Menghapus Align untuk mencegah pemaksaan maxWidth secara horizontal
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
            color: message.isRead ? Colors.blue : AppColors.timestamp,
          ),
        ],
      ],
    );
  }
}
