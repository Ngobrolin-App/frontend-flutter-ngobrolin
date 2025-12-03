import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../../../theme/app_colors.dart';
import '../../localization/app_localizations.dart';
import '../../models/message.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isMe,
  }) : super(key: key);

  Future<void> _downloadAndOpen(BuildContext context, String url) async {
    final dir = await getTemporaryDirectory();
    final segs = Uri.parse(url).pathSegments;
    final name = segs.isNotEmpty ? segs.last : 'file_${DateTime.now().millisecondsSinceEpoch}';
    final path = '${dir.path}/$name';
    await Dio().download(url, path);
    await OpenFile.open(path);
  }

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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.type == 'image') ...[
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 2),
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              insetPadding: const EdgeInsets.all(16),
                              child: PhotoView(
                                imageProvider: NetworkImage(message.content),
                                backgroundDecoration: const BoxDecoration(
                                  color: Colors.transparent,
                                ),
                                initialScale: PhotoViewComputedScale.contained,
                              ),
                            ),
                          );
                        },
                        onLongPress: () => _downloadAndOpen(context, message.content),
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
                  ] else if (message.type == 'file') ...[
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 2),
                      child: InkWell(
                        onTap: () => _downloadAndOpen(context, message.content),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Iconify(
                              MaterialSymbols.file_copy_rounded,
                              size: 18,
                              color: AppColors.text,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                Uri.parse(message.content).pathSegments.isNotEmpty
                                    ? Uri.parse(message.content).pathSegments.last
                                    : context.tr('file'),
                                style: const TextStyle(fontSize: 16, color: AppColors.text),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    Text(message.content, style: const TextStyle(fontSize: 16, color: AppColors.text)),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        context.loc.formatTime(message.createdAt),
                        style: const TextStyle(fontSize: 12, color: AppColors.timestamp),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Iconify(
                          message.isRead ? MaterialSymbols.done_all_rounded : MaterialSymbols.done_rounded,
                          size: 14,
                          color: message.isRead ? Colors.blue : AppColors.timestamp,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (message.type == 'file') ...[
              const SizedBox(width: 8),
              Iconify(MaterialSymbols.open_in_new, size: 24, color: AppColors.accent),
            ],
          ],
        ),
      ),
    );
  }
}
