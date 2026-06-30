import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart'; // Tambahkan package ini di pubspec.yaml
import 'package:ngobrolin_app/core/enums/reply_message_layout.dart';
import 'package:ngobrolin_app/core/models/message_model.dart';
import 'package:ngobrolin_app/core/viewmodels/chat/chat_view_model.dart';
import 'package:ngobrolin_app/core/widgets/cards/reply_message.dart';
import 'package:ngobrolin_app/core/widgets/inputs/chat_input_bar.dart';
import 'package:provider/provider.dart';

// Sesuaikan path import ini jika letak foldernya berbeda
import '../../core/localization/app_localizations.dart';
import '../../theme/app_colors.dart';

class ImagePreviewEditScreen extends StatefulWidget {
  final String imagePath;

  const ImagePreviewEditScreen({super.key, required this.imagePath});

  @override
  State<ImagePreviewEditScreen> createState() => _ImagePreviewEditScreenState();
}

class _ImagePreviewEditScreenState extends State<ImagePreviewEditScreen> {
  late String _currentImagePath;
  final TextEditingController _captionController = TextEditingController();
  int _turns = 0; // 0 = 0°, 1 = 90°, 2 = 180°, 3 = 270°
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.imagePath;
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _rotateImage() {
    setState(() {
      _turns = (_turns + 1) % 4;
    });
  }

  Future<void> _cropImage() async {
    try {
      // Jika gambar sedang diputar, kita bisa langsung crop file yang sedang aktif
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: _currentImagePath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Potong Gambar',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: AppColors.accent,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Potong Gambar',
            doneButtonTitle: 'Selesai',
            cancelButtonTitle: 'Batal',
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _currentImagePath = croppedFile.path;
          _turns = 0; // Reset rotasi setelah dicrop agar tidak membingungkan
        });
      }
    } catch (e) {
      developer.log('Error cropping image: $e', name: 'ImagePreviewEdit');
    }
  }

  Future<void> _handleSend() async {
    setState(() => _isProcessing = true);
    try {
      File finalFile = File(_currentImagePath);

      // Jika ada data rotasi yang belum dibakar, proses secara native terlebih dahulu
      if (_turns != 0) {
        finalFile = await _bakeRotationData(finalFile, _turns);
      }

      if (mounted) {
        // Mengembalikan data berupa Map yang berisi File gambar dan teks caption
        Navigator.pop(context, {
          'file': finalFile,
          'caption': _captionController.text.trim(),
        });
      }
    } catch (e) {
      developer.log('Error processing image: $e', name: 'ImagePreviewEdit');
      // Fallback: jika gagal, kirim file yang ada beserta caption daripada crash
      if (mounted) {
        Navigator.pop(context, {
          'file': File(_currentImagePath),
          'caption': _captionController.text.trim(),
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Memutar koordinat pixel gambar asli menggunakan Canvas secara native
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('preview_image'),
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          if (!_isProcessing) ...[
            IconButton(
              icon: const Icon(Icons.crop_rounded, size: 24),
              onPressed: _cropImage,
              tooltip: 'Potong Gambar',
            ),
            IconButton(
              icon: const Icon(Icons.rotate_right_rounded, size: 26),
              onPressed: _rotateImage,
              tooltip: 'Rotasi 90°',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Area Preview Gambar
          Expanded(
            child: Center(
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : RotatedBox(
                      quarterTurns: _turns,
                      child: Image.file(
                        File(_currentImagePath),
                        fit: BoxFit.contain,
                      ),
                    ),
            ),
          ),
          Selector<ChatViewModel, (MessageModel?, bool)>(
            selector: (_, vm) => (vm.replyingToMessage, vm.isLoading),
            builder: (context, state, _) {
              final replyingTo = state.$1;

              return ChatInputBar(
                controller: _captionController,
                hintText: context.tr("add_caption"),
                showAttachment: false,
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
              );
            },
          ),
        ],
      ),
    );
  }
}
