import 'package:flutter/material.dart';
import 'package:ngobrolin_app/core/models/message_model.dart';
import 'package:ngobrolin_app/core/utils/chat_utils.dart';
import 'package:ngobrolin_app/theme/app_colors.dart';

class ChatSystemMessageBadge extends StatelessWidget {
  final MessageModel message;

  const ChatSystemMessageBadge({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          ChatUtils.getSystemMessageText(message, context),
          textAlign: TextAlign.center,
          maxLines: 3,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.text,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
