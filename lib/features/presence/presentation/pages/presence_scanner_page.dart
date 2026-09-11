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

class _PresenceScannerPageState extends State<PresenceScannerPage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static const LinearGradient _mainGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF003D82), Color(0xFF0056B3)],
  );

  late final MobileScannerController _scannerController;
  late final AnimationController _animController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
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
    _animController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.trim().isNotEmpty) {
        _navigateToProcessPage(qrCode: code.trim());
        break;
      }
    }
  }

  Future<void> _navigateToProcessPage({String? qrCode, String? shortCode}) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      await _scannerController.stop();
    } catch (_) {}

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
      try {
        await _scannerController.start();
      } catch (_) {}
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
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 16,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: _mainGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.pin_rounded,
                        color: Colors.white,
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
                const SizedBox(height: 24),
                TextFormField(
                  controller: textController,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.text,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.inputShortCodeHint,
                    hintStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      letterSpacing: 0,
                      color: Colors.grey.shade400,
                    ),
                    prefixIcon: const Icon(Icons.dialpad_rounded, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20, color: Colors.grey),
                      onPressed: () => textController.clear(),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
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
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    gradient: _mainGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
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
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
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

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          toolbarHeight: 70,
          backgroundColor: const Color(0xFF003D82),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            l10n.scanQrTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: _mainGradient),
          ),
          actions: [
            // Flash On / Off Button (using reactive ValueListenableBuilder)
            ValueListenableBuilder<MobileScannerState>(
              valueListenable: _scannerController,
              builder: (context, state, child) {
                final isTorchOn = state.torchState == TorchState.on;
                final isTorchAvailable = state.torchState != TorchState.unavailable;

                return IconButton(
                  tooltip: isTorchOn ? l10n.flashOff : l10n.flashOn,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isTorchOn
                          ? Colors.amberAccent.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      color: isTorchOn ? Colors.amberAccent : Colors.white,
                      size: 20,
                    ),
                  ),
                  onPressed: isTorchAvailable
                      ? () async {
                          try {
                            await _scannerController.toggleTorch();
                          } catch (e) {
                            debugPrint('Error toggling torch: $e');
                          }
                        }
                      : null,
                );
              },
            ),
            // Short Code Action Icon in AppBar
            IconButton(
              tooltip: l10n.useShortCode,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.dialpad_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: _showShortCodeBottomSheet,
            ),
            const SizedBox(width: 8),
          ],
        ),
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

            // 2. Viewfinder Overlay with Animated Scanline (IgnorePointer ensures touches pass through)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, _) {
                    return CustomPaint(
                      size: Size(size.width, size.height),
                      painter: _ScannerOverlayPainter(
                        scanBoxSize: scanBoxSize,
                        borderColor: const Color(0xFF38BDF8),
                        scanProgress: _animController.value,
                      ),
                    );
                  },
                ),
              ),
            ),

            // 3. Instruction Chip below scanner box
            Positioned(
              top: (size.height / 2) + (scanBoxSize / 2) - 30,
              left: 28,
              right: 28,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF38BDF8), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.scanQrInstruction,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Prominent Bottom Menu: Short Code Input Card
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: SafeArea(
                top: false,
                child: InkWell(
                  onTap: _showShortCodeBottomSheet,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: _mainGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.dialpad_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.useShortCode,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.cantScanQrQuestion,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Input',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter to draw the dark semi-transparent mask, corner accents, and animated laser line
class _ScannerOverlayPainter extends CustomPainter {
  final double scanBoxSize;
  final Color borderColor;
  final double scanProgress;

  _ScannerOverlayPainter({
    required this.scanBoxSize,
    required this.borderColor,
    required this.scanProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);

    final left = (size.width - scanBoxSize) / 2;
    final top = (size.height - scanBoxSize) / 2 - 40; // Slight upward offset for aesthetic balance
    final rect = Rect.fromLTWH(left, top, scanBoxSize, scanBoxSize);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(24));

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
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    const cornerLength = 32.0;

    // Top Left
    canvas.drawLine(Offset(left + 8, top), Offset(left + 8 + cornerLength, top), cornerPaint);
    canvas.drawLine(Offset(left, top + 8), Offset(left, top + 8 + cornerLength), cornerPaint);

    // Top Right
    canvas.drawLine(Offset(left + scanBoxSize - 8 - cornerLength, top), Offset(left + scanBoxSize - 8, top), cornerPaint);
    canvas.drawLine(Offset(left + scanBoxSize, top + 8), Offset(left + scanBoxSize, top + 8 + cornerLength), cornerPaint);

    // Bottom Left
    canvas.drawLine(Offset(left + 8, top + scanBoxSize), Offset(left + 8 + cornerLength, top + scanBoxSize), cornerPaint);
    canvas.drawLine(Offset(left, top + scanBoxSize - 8 - cornerLength), Offset(left, top + scanBoxSize - 8), cornerPaint);

    // Bottom Right
    canvas.drawLine(Offset(left + scanBoxSize - 8 - cornerLength, top + scanBoxSize), Offset(left + scanBoxSize - 8, top + scanBoxSize), cornerPaint);
    canvas.drawLine(Offset(left + scanBoxSize, top + scanBoxSize - 8 - cornerLength), Offset(left + scanBoxSize, top + scanBoxSize - 8), cornerPaint);

    // Draw Animated Laser Scan Line
    final laserY = top + (scanBoxSize * scanProgress);
    final laserPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          borderColor.withValues(alpha: 0.0),
          borderColor.withValues(alpha: 0.85),
          Colors.white,
          borderColor.withValues(alpha: 0.85),
          borderColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(left + 16, laserY, scanBoxSize - 32, 3))
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(left + 16, laserY),
      Offset(left + scanBoxSize - 16, laserY),
      laserPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress ||
        oldDelegate.scanBoxSize != scanBoxSize ||
        oldDelegate.borderColor != borderColor;
  }
}
