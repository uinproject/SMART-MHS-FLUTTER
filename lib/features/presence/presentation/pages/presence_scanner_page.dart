import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smartmahsiswaflutter/core/theme/app_colors.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import 'presence_process_page.dart';

class PresenceScannerPage extends StatefulWidget {
  const PresenceScannerPage({super.key});

  @override
  State<PresenceScannerPage> createState() => _PresenceScannerPageState();
}

class _PresenceScannerPageState extends State<PresenceScannerPage> with WidgetsBindingObserver {
  late MobileScannerController _scannerController;
  bool _isProcessing = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_scannerController.value.isInitialized) return;

    switch (state) {
      case AppLifecycleState.resumed:
        if (!_isProcessing) {
          _scannerController.start();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _scannerController.stop();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.trim().isNotEmpty) {
        _isProcessing = true;
        _navigateToProcessPage(qrCode: code.trim());
        break;
      }
    }
  }

  Future<void> _navigateToProcessPage({String? qrCode, String? shortCode}) async {
    await _scannerController.stop();
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PresenceProcessPage(
          qrCode: qrCode,
          shortCode: shortCode,
        ),
      ),
    );

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
      _scannerController.start();
    }
  }

  void _showShortCodeBottomSheet() {
    final l10n = AppLocalizations.of(context)!;
    final textController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
            left: 24,
            right: 24,
            top: 16,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.pin_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.useShortCode,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.cantScanQrQuestion,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: textController,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.inputShortCodeHint,
                    prefixIcon: const Icon(Icons.code_rounded, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return l10n.shortCodeEmpty;
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.pop(modalContext);
                      _navigateToProcessPage(shortCode: textController.text.trim());
                    }
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.pop(modalContext);
                      _navigateToProcessPage(shortCode: textController.text.trim());
                    }
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                  label: Text(
                    l10n.submit,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final scanBoxSize = size.width * 0.72;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Mobile Scanner View
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.videocam_off_rounded, color: Colors.white70, size: 56),
                      const SizedBox(height: 16),
                      Text(
                        l10n.cameraPermissionDenied,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 2. Dark Mask Overlay with center transparent cut-out
          CustomPaint(
            size: Size(size.width, size.height),
            painter: _ScannerOverlayPainter(
              scanBoxSize: scanBoxSize,
              borderColor: AppColors.primary,
            ),
          ),

          // 3. Top Action Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  _buildCircleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  // Title
                  Text(
                    l10n.scanQrTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 6),
                      ],
                    ),
                  ),
                  // Flash & Switch Camera Buttons
                  Row(
                    children: [
                      _buildCircleButton(
                        icon: _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                        iconColor: _isTorchOn ? Colors.amberAccent : Colors.white,
                        onTap: () async {
                          await _scannerController.toggleTorch();
                          setState(() {
                            _isTorchOn = !_isTorchOn;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildCircleButton(
                        icon: Icons.cameraswitch_rounded,
                        onTap: () => _scannerController.switchCamera(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 4. Instructions below scanner box
          Positioned(
            top: (size.height / 2) + (scanBoxSize / 2) + 24,
            left: 32,
            right: 32,
            child: Text(
              l10n.scanQrInstruction,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(color: Colors.black87, blurRadius: 8),
                ],
              ),
            ),
          ),

          // 5. Bottom Alternate: Short Code Card
          Positioned(
            bottom: 32,
            left: 20,
            right: 20,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.pin_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.useShortCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _showShortCodeBottomSheet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        l10n.enterNim.isNotEmpty ? l10n.useShortCode.split(' ').first : 'Input',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }
}

/// Custom painter to draw the dark semi-transparent mask and corner borders around the scan box
class _ScannerOverlayPainter extends CustomPainter {
  final double scanBoxSize;
  final Color borderColor;

  _ScannerOverlayPainter({
    required this.scanBoxSize,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);

    final left = (size.width - scanBoxSize) / 2;
    final top = (size.height - scanBoxSize) / 2;
    final rect = Rect.fromLTWH(left, top, scanBoxSize, scanBoxSize);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(20));

    // Draw background mask with cut out
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, backgroundPaint);

    // Draw 4 corner accents
    final cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    const cornerLength = 28.0;

    // Top Left
    canvas.drawLine(Offset(left + 6, top), Offset(left + 6 + cornerLength, top), cornerPaint);
    canvas.drawLine(Offset(left, top + 6), Offset(left, top + 6 + cornerLength), cornerPaint);

    // Top Right
    canvas.drawLine(Offset(left + scanBoxSize - 6 - cornerLength, top), Offset(left + scanBoxSize - 6, top), cornerPaint);
    canvas.drawLine(Offset(left + scanBoxSize, top + 6), Offset(left + scanBoxSize, top + 6 + cornerLength), cornerPaint);

    // Bottom Left
    canvas.drawLine(Offset(left + 6, top + scanBoxSize), Offset(left + 6 + cornerLength, top + scanBoxSize), cornerPaint);
    canvas.drawLine(Offset(left, top + scanBoxSize - 6 - cornerLength), Offset(left, top + scanBoxSize - 6), cornerPaint);

    // Bottom Right
    canvas.drawLine(Offset(left + scanBoxSize - 6 - cornerLength, top + scanBoxSize), Offset(left + scanBoxSize - 6, top + scanBoxSize), cornerPaint);
    canvas.drawLine(Offset(left + scanBoxSize, top + scanBoxSize - 6 - cornerLength), Offset(left + scanBoxSize, top + scanBoxSize - 6), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanBoxSize != scanBoxSize || oldDelegate.borderColor != borderColor;
  }
}
