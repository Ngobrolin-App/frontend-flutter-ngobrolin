import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:ngobrolin_app/core/enums/reply_message_layout.dart';
import 'package:ngobrolin_app/core/models/message_model.dart';
import 'package:ngobrolin_app/core/utils/general_utils.dart';
import 'package:ngobrolin_app/core/viewmodels/chat/chat_view_model.dart';
import 'package:ngobrolin_app/core/widgets/cards/reply_message.dart';
import 'package:ngobrolin_app/core/widgets/inputs/chat_input_bar.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path; // WAJIB TAMBAHKAN INI

import '../../core/localization/app_localizations.dart';
import '../../theme/app_colors.dart';

class AttachmentPreviewScreen extends StatefulWidget {
  final String filePath;
  final String fileType; // 'image' atau 'file'

  const AttachmentPreviewScreen({
    super.key,
    required this.filePath,
    required this.fileType,
  });

  @override
  State<AttachmentPreviewScreen> createState() =>
      _AttachmentPreviewScreenState();
}

class _AttachmentPreviewScreenState extends State<AttachmentPreviewScreen> {
  late String _currentFilePath;
  final TextEditingController _captionController = TextEditingController();
  int _turns = 0;
  bool _isProcessing = false;

  bool get _isImage => widget.fileType == 'image';

  @override
  void initState() {
    super.initState();
    _currentFilePath = widget.filePath;
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _rotateImage() {
    if (!_isImage) return;
    setState(() {
      _turns = (_turns + 1) % 4;
    });
  }

  Future<void> _cropImage() async {
    if (!_isImage) return;
    try {
      final croppedFile = await GeneralUtils.cropImage(
        sourcePath: _currentFilePath,
        title: context.tr('crop_image'),
        isSquare: false,
      );

      if (croppedFile != null) {
        setState(() {
          _currentFilePath = croppedFile.path;
          _turns = 0;
        });
      }
    } catch (e) {
      developer.log(
        'AttachmentPreview - _cropImage() error $e',
        name: 'AttachmentPreview',
      );
    }
  }

  Future<void> _handleSend() async {
    setState(() => _isProcessing = true);
    try {
      File finalFile = File(_currentFilePath);

      // Hanya proses rotasi native JIKA tipenya gambar dan ada perubahan rotasi
      if (_isImage && _turns != 0) {
        finalFile = await _bakeRotationData(finalFile, _turns);
      }

      if (mounted) {
        final fileDetails = await GeneralUtils.getFileDetails(finalFile);

        final dataToSend = {
          'mediaFile': finalFile,
          'content': _captionController.text.trim(),
          'mediaSize': fileDetails['size'],
          'mediaFileType': fileDetails['mimeType'],
          'mediaFileName': fileDetails['fileName'],
        };

        Navigator.pop(context, dataToSend);
      }
    } catch (e) {
      developer.log(
        'AttachmentPreview - _handleSend() error $e',
        name: 'AttachmentPreview',
      );
      if (mounted) {
        Navigator.pop(context, {
          'mediaFile': File(_currentFilePath),
          'content': _captionController.text.trim(),
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<File> _bakeRotationData(File file, int turns) async {
    final Uint8List bytes = await file.readAsBytes();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image image = frameInfo.image;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    int targetWidth = image.width;
    int targetHeight = image.height;

    if (turns % 2 != 0) {
      targetWidth = image.height;
      targetHeight = image.width;
    }

    if (turns == 1) {
      canvas.translate(targetWidth.toDouble(), 0);
      canvas.rotate(math.pi / 2);
    } else if (turns == 2) {
      canvas.translate(targetWidth.toDouble(), targetHeight.toDouble());
      canvas.rotate(math.pi);
    } else if (turns == 3) {
      canvas.translate(0, targetHeight.toDouble());
      canvas.rotate(3 * math.pi / 2);
    }

    canvas.drawImage(image, Offset.zero, Paint());

    final ui.Image rotatedImage = await recorder.endRecording().toImage(
      targetWidth,
      targetHeight,
    );
    final ByteData? byteData = await rotatedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final Uint8List rotatedBytes = byteData!.buffer.asUint8List();

    final String dir = file.parent.path;
    final String newPath =
        '$dir/edited_${DateTime.now().millisecondsSinceEpoch}.png';
    final File newFile = File(newPath);
    await newFile.writeAsBytes(rotatedBytes);

    return newFile;
  }

  // WIDGET PREVIEW DINAMIS
  Widget _buildPreviewArea() {
    if (_isImage) {
      return RotatedBox(
        quarterTurns: _turns,
        child: Image.file(File(_currentFilePath), fit: BoxFit.contain),
      );
    } else {
      // Tampilan untuk File/Document
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insert_drive_file, size: 80, color: Colors.white70),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              path.basename(_currentFilePath),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.fileType.toUpperCase(), // Menampilkan format teks simpel
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.black, // Beri background gelap agar preview lebih fokus
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          context.tr(
            'preview_attachment',
          ), // Pastikan di app_localizations ada translasi ini
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          // Tampilkan icon crop dan rotate HANYA jika fileType adalah gambar
          if (!_isProcessing && _isImage) ...[
            IconButton(
              icon: const Icon(
                Icons.crop_rounded,
                size: 24,
                color: Colors.white,
              ),
              onPressed: _cropImage,
              tooltip: 'Potong Gambar',
            ),
            IconButton(
              icon: const Icon(
                Icons.rotate_right_rounded,
                size: 26,
                color: Colors.white,
              ),
              onPressed: _rotateImage,
              tooltip: 'Rotasi 90°',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Area Preview Dinamis
          Expanded(
            child: Center(
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : _buildPreviewArea(),
            ),
          ),

          // Area Input Caption
          Selector<ChatViewModel, (MessageModel?, bool)>(
            selector: (_, vm) => (vm.replyingToMessage, vm.isLoading),
            builder: (context, state, _) {
              final replyingTo = state.$1;

              return Container(
                color: Theme.of(
                  context,
                ).scaffoldBackgroundColor, // Kembalikan ke warna asli input bar
                child: ChatInputBar(
                  controller: _captionController,
                  hintText: context.tr("add_caption"),
                  showAttachment:
                      false, // Sembunyikan ikon attachment di dalam preview
                  isSending: _isProcessing,
                  onSend: _handleSend,
                  top: replyingTo == null
                      ? null
                      : ReplyMessageWidget(
                          message: replyingTo,
                          layout: ReplyMessageLayout.composer,
                          onClose: () {
                            context.read<ChatViewModel>().setReplyingTo(null);
                          },
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
