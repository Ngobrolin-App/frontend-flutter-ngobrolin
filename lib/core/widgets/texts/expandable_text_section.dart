import 'package:flutter/material.dart';
import 'package:ngobrolin_app/core/localization/app_localizations.dart';
import 'package:ngobrolin_app/core/widgets/modals/app_bottom_sheet.dart';
import 'package:ngobrolin_app/theme/app_colors.dart';

class ExpandableTextSection extends StatelessWidget {
  final String title;
  final String content;
  final Widget? emptyContentWidget;
  final VoidCallback? onEdit;
  final int maxLines;

  const ExpandableTextSection({
    super.key,
    required this.title,
    required this.content,
    this.emptyContentWidget,
    this.onEdit,
    this.maxLines = 1,
  });

  void _showDetailModal(BuildContext context) {
    AppBottomSheet.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                  const SizedBox(width: 48),
              ],
            ),
          ),
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
              const textStyle = TextStyle(fontSize: 16);
              final readMoreStyle = TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              );

              final span = TextSpan(text: content, style: textStyle);
              final tp = TextPainter(
                text: span,
                maxLines: maxLines, // 2. Gunakan maxLines
                textDirection: TextDirection.ltr,
              );
              tp.layout(maxWidth: constraints.maxWidth);

              if (tp.didExceedMaxLines) {
                // 3. Binary Search untuk mencari titik potong teks yang pas
                int start = 0;
                int end = content.length;
                int maxValidIndex = 0;

                while (start <= end) {
                  int mid = start + (end - start) ~/ 2;

                  final exactTestSpan = TextSpan(
                    style: textStyle,
                    children: [
                      TextSpan(text: content.substring(0, mid)),
                      const TextSpan(text: '... '),
                      TextSpan(
                        text: context.tr('read_more'),
                        style: readMoreStyle,
                      ),
                    ],
                  );

                  final testTp = TextPainter(
                    text: exactTestSpan,
                    maxLines: maxLines,
                    textDirection: TextDirection.ltr,
                  );
                  testTp.layout(maxWidth: constraints.maxWidth);

                  if (testTp.didExceedMaxLines) {
                    end = mid - 1; // Jika kepanjangan, kurangi jumlah karakter
                  } else {
                    maxValidIndex =
                        mid; // Jika muat, simpan index dan coba lebih panjang
                    start = mid + 1;
                  }
                }

                // 4. Render Text.rich yang inline dan seamless
                return GestureDetector(
                  onTap: () =>
                      _showDetailModal(context), // Seluruh teks bisa di-tap
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: content.substring(0, maxValidIndex)),
                        const TextSpan(text: '... '),
                        TextSpan(
                          text: context.tr('read_more'),
                          style: readMoreStyle,
                        ),
                      ],
                    ),
                    style: textStyle,
                    maxLines: maxLines,
                  ),
                );
              } else {
                return GestureDetector(
                  onTap: onEdit != null ? () => onEdit!() : null,
                  child: Text(content, style: textStyle),
                );
              }
            },
          ),
      ],
    );
  }
}
