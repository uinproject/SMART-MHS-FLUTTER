import 'package:flutter/material.dart';

class AnnouncementImageViewPage extends StatefulWidget {
  final String imageUrl;
  final String? title;

  const AnnouncementImageViewPage({
    super.key,
    required this.imageUrl,
    this.title,
  });

  @override
  State<AnnouncementImageViewPage> createState() =>
      _AnnouncementImageViewPageState();
}

class _AnnouncementImageViewPageState extends State<AnnouncementImageViewPage>
    with SingleTickerProviderStateMixin {
  late final TransformationController _transformationController;
  TapDownDetails? _doubleTapDetails;
  bool _showOverlay = true;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      // Reset zoom
      _transformationController.value = Matrix4.identity();
    } else {
      // Zoom in ke titik double tap
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      final x = -position.dx * 1.5;
      final y = -position.dy * 1.5;
      _transformationController.value = Matrix4.identity()
        ..translateByDouble(x, y, 0.0, 1.0)
        ..scaleByDouble(2.5, 2.5, 1.0, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _showOverlay
          ? AppBar(
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: widget.title != null && widget.title!.isNotEmpty
                  ? Text(
                      widget.title!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
            )
          : null,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showOverlay = !_showOverlay;
          });
        },
        onDoubleTapDown: (details) => _doubleTapDetails = details,
        onDoubleTap: _handleDoubleTap,
        child: SizedBox.expand(
          child: InteractiveViewer(
            transformationController: _transformationController,
            clipBehavior: Clip.none,
            panEnabled: true,
            scaleEnabled: true,
            minScale: 0.8,
            maxScale: 5.0,
            boundaryMargin: EdgeInsets.all(screenSize.longestSide),
            child: SizedBox(
              width: screenSize.width,
              height: screenSize.height,
              child: Image.network(
                widget.imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image_rounded,
                        color: Colors.white54,
                        size: 64,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Gagal memuat gambar',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
