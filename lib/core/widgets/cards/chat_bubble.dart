import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import '../../../theme/app_colors.dart';
import '../../localization/app_localizations.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final String type;
  final DateTime timestamp;
  final bool isMe;
  final bool isRead;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.timestamp,
    required this.isMe,
    this.isRead = false,
    required this.type,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (type == 'image') ...[
              Container(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        insetPadding: const EdgeInsets.all(16),
                        child: PhotoView(
                          imageProvider: NetworkImage(message),
                          backgroundDecoration: const BoxDecoration(color: Colors.transparent),
                          initialScale: PhotoViewComputedScale.contained,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: message,
                      width: MediaQuery.of(context).size.width * 0.6,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ] else if (type == 'file') ...[
              Container(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.insert_drive_file, color: AppColors.text),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        Uri.parse(message).pathSegments.isNotEmpty
                            ? Uri.parse(message).pathSegments.last
                            : context.tr('file'),
                        style: const TextStyle(fontSize: 16, color: AppColors.text),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(message, style: const TextStyle(fontSize: 16, color: AppColors.text)),
            ],
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  context.loc.formatTime(timestamp),
                  style: const TextStyle(fontSize: 12, color: AppColors.timestamp),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Iconify(
                    isRead ? MaterialSymbols.done_all_rounded : MaterialSymbols.done_rounded,
                    size: 14,
                    color: isRead ? Colors.blue : AppColors.timestamp,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
