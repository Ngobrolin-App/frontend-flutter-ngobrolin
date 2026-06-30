import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:ngobrolin_app/core/enums/reply_message_layout.dart';

import '../../../theme/app_colors.dart';
import '../../localization/app_localizations.dart';
import '../../models/message_model.dart';

class ReplyMessageWidget extends StatelessWidget {
  final MessageModel message;
  final ReplyMessageLayout layout;
  final VoidCallback? onTap;
  final VoidCallback? onClose;

  const ReplyMessageWidget({
    super.key,
    required this.message,
    this.layout = ReplyMessageLayout.bubble,
    this.onTap,
    this.onClose,
  });

  bool get _showThumbnail => message.type == 'image';

  bool get _thumbnailLeft => layout == ReplyMessageLayout.composer;

  bool get _showClose => layout == ReplyMessageLayout.composer;

  String _extractFileName(String? url, String fallback) {
    if (url == null || url.isEmpty) return fallback;

    final uri = Uri.tryParse(url);

    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }

    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.lightGrey.withOpacity(.5),
          border: const Border(
            left: BorderSide(color: AppColors.primary, width: 4),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_showThumbnail && _thumbnailLeft)
              _ReplyThumbnail(imageUrl: message.content, left: true),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.sender?.name ?? "-",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _buildPreview(context),
                  ],
                ),
              ),
            ),

            if (_showThumbnail && !_thumbnailLeft)
              _ReplyThumbnail(imageUrl: message.content, left: false),

            if (_showClose)
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: onClose,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    switch (message.type) {
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

      case 'file':
        return Row(
          children: [
            const Iconify(
              Mdi.file_document_outline,
              size: 18,
              color: AppColors.text,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _extractFileName(message.content, context.tr('file')),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.text),
              ),
            ),
          ],
        );

      default:
        return Text(
          message.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppColors.text),
        );
    }
  }
}

class _ReplyThumbnail extends StatelessWidget {
  final String imageUrl;
  final bool left;

  const _ReplyThumbnail({required this.imageUrl, required this.left});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: left
          ? const BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomLeft: Radius.circular(8),
            )
          : const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: 70,
        height: 70,
        fit: BoxFit.cover,
      ),
    );
  }
}
