import 'package:flutter/material.dart';
import 'package:ngobrolin_app/core/localization/app_localizations.dart';
import 'package:ngobrolin_app/theme/app_colors.dart';

class ExpandableTextSection extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback? onEdit;

  const ExpandableTextSection({
    super.key,
    required this.title,
    required this.content,
    this.onEdit,
  });

  void _showDetailModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Mengizinkan modal menyesuaikan tinggi > 50%
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(context).size.height *
                  0.9, // Maksimal tinggi layar
            ),
            decoration: const BoxDecoration(
              color:
                  AppColors.white, // Sesuaikan dengan warna surface theme kamu
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Modal setinggi konten
              children: [
                // 1. Drag Handle Indicator
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    height: 5,
                    width: 48,
                    decoration: BoxDecoration(
                      color: AppColors.grey.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                // 2. Header Row (Close, Title, Edit)
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
                          icon: const Icon(
                            Icons.edit,
                            color: AppColors.primary,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop(); // Tutup modal dulu
                            onEdit!(); // Eksekusi fungsi edit
                          },
                        )
                      else
                        const SizedBox(width: 48), // Spacer penyeimbang tengah
                    ],
                  ),
                ),
                // const Divider(height: 1),
                // 3. Full Content (Scrollable jika kepanjangan)
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            // Gunakan TextPainter untuk mengukur apakah teks melebihi 1 baris
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
              // Jika konten panjang, potong ellipsis dan tampilkan Read More
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
              // Jika konten pendek, render normal saja
              return Text(content, style: const TextStyle(fontSize: 16));
            }
          },
        ),
      ],
    );
  }
}
