import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:ngobrolin_app/theme/app_colors.dart';
import 'package:photo_view/photo_view.dart';
import 'package:ngobrolin_app/core/utils/media_utils.dart';
import 'package:ngobrolin_app/core/widgets/states/image_error_placeholder.dart';

class FullscreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final String? caption;
  final bool showDownloadButton;

  const FullscreenImageViewer({
    super.key,
    required this.imageUrl,
    this.caption,
    this.showDownloadButton = true,
  });

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.showDownloadButton)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: _isDownloading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          value: _downloadProgress == -1.0
                              ? null
                              : _downloadProgress,
                          strokeWidth: 2.5,
                          color: AppColors.white,
                          backgroundColor: Colors.white24,
                        ),
                      )
                    : InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () async {
                          if (_isDownloading) return;

                          setState(() {
                            _isDownloading = true;
                            _downloadProgress = 0.0;
                          });

                          await MediaUtils.downloadAndOpen(
                            context,
                            widget.imageUrl,
                            onProgress: (progress) {
                              if (mounted) {
                                setState(() {
                                  _downloadProgress = progress;
                                });
                              }
                            },
                          );

                          if (mounted) {
                            setState(() {
                              _isDownloading = false;
                            });
                          }
                        },
                        child: Iconify(
                          MaterialSymbols.download_rounded,
                          size: 24,
                          color: AppColors.white,
                        ),
                      ),
              ),
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Center(
            child: PhotoView(
              imageProvider: NetworkImage(widget.imageUrl),
              initialScale: PhotoViewComputedScale.contained,
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: ImageErrorPlaceholder(
                    width: double.infinity,
                    height: double.infinity,
                    iconSize: 48,
                    errorMessage: 'Gagal memuat gambar',
                  ),
                );
              },
            ),
          ),

          // Caption di bagian bawah (jika ada)
          if (widget.caption != null && widget.caption!.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      AppColors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  widget.caption!,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
