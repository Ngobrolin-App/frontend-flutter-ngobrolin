import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;

  final FocusNode? focusNode;

  final Widget? top;

  final VoidCallback onSend;

  final VoidCallback? onAttachment;

  final String hintText;

  final bool enabled;

  final bool isSending;

  final bool showAttachment;

  final int minLines;

  final int maxLines;

  final TextInputAction textInputAction;

  final ValueChanged<String>? onSubmitted;

  final ValueChanged<String>? onChanged;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.focusNode,
    this.top,
    this.onAttachment,
    this.hintText = '',
    this.enabled = true,
    this.isSending = false,
    this.showAttachment = true,
    this.minLines = 1,
    this.maxLines = 4,
    this.textInputAction = TextInputAction.newline,
    this.onSubmitted,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (top != null) ...[
            Padding(padding: const EdgeInsets.only(bottom: 8), child: top!),
          ],

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (showAttachment)
                IconButton(
                  icon: const Icon(Icons.attach_file, color: AppColors.grey),
                  onPressed: enabled ? onAttachment : null,
                ),

              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: enabled,
                  minLines: minLines,
                  maxLines: maxLines,
                  keyboardType: TextInputType.multiline,
                  textInputAction: textInputAction,
                  cursorColor: AppColors.accent,
                  onSubmitted: onSubmitted,
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.lightGrey.withOpacity(.3),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ),

              IconButton(
                onPressed: isSending ? null : onSend,
                icon: isSending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accent,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: AppColors.accent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
