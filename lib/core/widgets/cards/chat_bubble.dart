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
import 'package:ngobrolin_app/routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:iconify_flutter/icons/ion.dart';
import 'package:ngobrolin_app/core/viewmodels/chat/chat_view_model.dart';
import '../../../theme/app_colors.dart';
import '../../localization/app_localizations.dart';
import '../../models/message_model.dart';

class ChatBubble extends StatefulWidget {
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

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _isDownloaded = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _checkDownloadStatus();
  }

  Future<void> _checkDownloadStatus() async {
    if (widget.message.type == 'file') {
      bool downloaded = await MediaUtils.isFileDownloaded(
        widget.message.mediaUrl ?? '',
        fileName: widget.message.mediaFileName,
      );
      if (mounted) {
        setState(() {
          _isDownloaded = downloaded;
        });
      }
    }
  }

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
    switch (value) {
      case 'reply':
        context.read<ChatViewModel>().setReplyingTo(widget.message);
        break;
      case 'copy':
        Clipboard.setData(ClipboardData(text: widget.message.content ?? ''));
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
        MediaUtils.downloadAndOpen(
          context,
          widget.message.mediaUrl ?? '',
          fileName: widget.message.mediaFileName,
        );
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
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPressStart: widget.isLongPressOptionEnabled
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
            color: widget.isMe
                ? AppColors.chatBubbleUser
                : AppColors.chatBubbleOther,
            borderRadius: BorderRadius.circular(16).copyWith(
              bottomRight: widget.isMe ? const Radius.circular(4) : null,
              bottomLeft: !widget.isMe ? const Radius.circular(4) : null,
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
                if (!widget.isMe &&
                    (widget.conversationType == ConversationType.group) &&
                    widget.showSenderName)
                  Align(
                    alignment: widget.isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 8,
                        left: 8,
                        right: 8,
                        bottom: (widget.message.repliedMessage != null) ? 4 : 0,
                      ),
                      child: Text(
                        widget.message.sender?.name ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.buttonText,
                        ),
                      ),
                    ),
                  ),

                if (widget.message.repliedMessage != null) ...[
                  const SizedBox(height: 4),
                  _buildRepliedMessage(context),
                  const SizedBox(height: 4),
                ],
                if (widget.message.forwardedFromMessageId != null)
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
      message: widget.message.repliedMessage!,
      onTap: () {
        if (widget.message.repliedMessage!.id != null) {
          widget.onReplyTap?.call(widget.message.repliedMessage!.id);
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
    switch (widget.message.type) {
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
      widget.message.content ?? '',
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
                Navigator.pushNamed(
                  context,
                  AppRoutes.fullscreenImage,
                  arguments: {
                    'imageUrl': widget.message.mediaUrl ?? '',
                    'caption': widget.message.content,
                    'showDownloadButton': true,
                  },
                );
              },

              onLongPressStart: widget.isLongPressOptionEnabled
                  ? (details) => _showContextMenu(
                      context: context,
                      position: details.globalPosition,
                      showDownloadAndOpen: true,
                    )
                  : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: widget.message.mediaUrl ?? '',
                  width: MediaQuery.of(context).size.width * 0.6,
                  fit: BoxFit.cover,
                  progressIndicatorBuilder: (context, url, downloadProgress) =>
                      Container(
                        width: MediaQuery.of(context).size.width * 0.6,
                        height: 160,
                        alignment: Alignment.center,
                        color: AppColors.lightGrey,
                        child: CircularProgressIndicator(
                          value: downloadProgress.progress,
                          strokeWidth: 3.0,
                        ),
                      ),
                  errorWidget: (context, url, error) => ImageErrorPlaceholder(
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: 160,
                    iconSize: 40,
                    errorMessage: context.tr('failed_to_load_image'),
                  ),
                ),
              ),
            ),

            if (widget.message.content?.isNotEmpty ?? false) ...[
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
            onTap: () async {
              if (_isDownloading) return;

              if (_isDownloaded) {
                await MediaUtils.openDownloadedFile(
                  widget.message.mediaUrl ?? '',
                  fileName: widget.message.mediaFileName,
                );
                return;
              }

              setState(() {
                _isDownloading = true;
                _downloadProgress = 0.0;
              });

              await MediaUtils.downloadAndOpen(
                context,
                widget.message.mediaUrl ?? '',
                fileName: widget.message.mediaFileName,
                onProgress: (progress) {
                  if (mounted) {
                    setState(() {
                      _downloadProgress = progress;
                    });
                  }
                },
              );

              if (mounted) {
                setState(() {
                  _isDownloading = false;
                  _isDownloaded = true;
                });
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Iconify(
                  Mdi.file_document,
                  size: 32,
                  color: AppColors.text,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _extractFileName(
                      widget.message.mediaFileName ?? '',
                      context.tr('file'),
                    ),
                    style: const TextStyle(fontSize: 16, color: AppColors.text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (_isDownloading)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      value: _downloadProgress == -1.0
                          ? null
                          : _downloadProgress,
                      strokeWidth: 3.0,
                      color: AppColors.accent,
                      backgroundColor: AppColors.lightGrey,
                    ),
                  )
                else if (_isDownloaded)
                  const Iconify(
                    MaterialSymbols.open_in_new,
                    size: 20,
                    color: AppColors.accent,
                  )
                else
                  const Iconify(
                    MaterialSymbols.download_rounded,
                    size: 24,
                    color: AppColors.accent,
                  ),
              ],
            ),
          ),
          if (widget.message.content?.isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            _buildTextMessage(context),
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
          context.loc.formatTime(widget.message.createdAt),
          style: const TextStyle(fontSize: 12, color: AppColors.timestamp),
        ),
        if (widget.isMe) ...[
          const SizedBox(width: 4),
          Iconify(
            widget.message.isRead
                ? MaterialSymbols.done_all_rounded
                : MaterialSymbols.done_rounded,
            size: 14,
            color: widget.message.isRead
                ? AppColors.messageRead
                : AppColors.timestamp,
          ),
        ],
      ],
    );
  }
}
