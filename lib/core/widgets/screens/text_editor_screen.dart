import 'package:flutter/material.dart';
import 'package:ngobrolin_app/core/localization/app_localizations.dart';
import 'package:ngobrolin_app/core/widgets/inputs/custom_text_field.dart'; // Sesuaikan path
import 'package:ngobrolin_app/theme/app_colors.dart';

class TextEditorScreen extends StatefulWidget {
  final String title;
  final String? initialValue;
  final String? description;
  final int? maxLength;
  final int? maxLines;

  const TextEditorScreen({
    super.key,
    required this.title,
    this.initialValue,
    this.description,
    this.maxLength,
    this.maxLines = 1,
  });

  @override
  State<TextEditorScreen> createState() => _TextEditorScreenState();
}

class _TextEditorScreenState extends State<TextEditorScreen> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Inisialisasi textfield dengan nilai lama (jika ada)
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor, // Sesuai tema (gelap/terang)
      appBar: AppBar(title: Text(widget.title), elevation: 0),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      controller: _controller,
                      autofocus: true,
                      maxLength: widget.maxLength,
                      maxLines: widget.maxLines,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                    ),

                    if (widget.description != null &&
                        widget.description!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        widget.description!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Action Buttons (Cancel & OK)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        context.tr('cancel'),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(_controller.text.trim());
                      },
                      child: Text(
                        context.tr('ok'),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
