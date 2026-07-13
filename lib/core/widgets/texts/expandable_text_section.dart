import 'package:flutter/material.dart';
import 'package:ngobrolin_app/core/localization/app_localizations.dart';
import 'package:ngobrolin_app/core/widgets/modals/app_bottom_sheet.dart';
import 'package:ngobrolin_app/theme/app_colors.dart';
// Import AppBottomSheet di sini

class ExpandableTextSection extends StatelessWidget {
  final String title;
  final String content;
  final Widget? emptyContentWidget;
  final VoidCallback? onEdit;

  const ExpandableTextSection({
    super.key,
    required this.title,
    required this.content,
    this.emptyContentWidget,
    this.onEdit,
  });

  void _showDetailModal(BuildContext context) {
    AppBottomSheet.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row (Close, Title, Edit)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.primary),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onEdit!();
                    },
                  )
                else
                  const SizedBox(width: 48), // Spacer penyeimbang tengah
              ],
            ),
          ),
          // Full Content (Scrollable)
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                content,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (content.isEmpty)
          emptyContentWidget ?? Text(context.tr('none'))
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final span = TextSpan(
                text: content,
                style: const TextStyle(fontSize: 16),
              );
              final tp = TextPainter(
                text: span,
                maxLines: 1,
                textDirection: TextDirection.ltr,
              );
              tp.layout(maxWidth: constraints.maxWidth);

              if (tp.didExceedMaxLines) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _showDetailModal(context),
                      child: Text(
                        context.tr('read_more'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return GestureDetector(
                  onTap: onEdit != null ? () => onEdit!() : null,
                  child: Text(content, style: const TextStyle(fontSize: 16)),
                );
              }
            },
          ),
      ],
    );
  }
}
