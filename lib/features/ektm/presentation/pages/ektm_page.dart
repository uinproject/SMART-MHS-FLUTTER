import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/storage/session_manager.dart';
import '../../../announcement/presentation/pages/announcement_image_view_page.dart';

enum EktmCodeType { qrCode, barcode }

class EktmPage extends StatefulWidget {
  const EktmPage({super.key});

  @override
  State<EktmPage> createState() => _EktmPageState();
}

class _EktmPageState extends State<EktmPage> {
  final _sessionManager = SessionManager();
  EktmCodeType _selectedType = EktmCodeType.qrCode;

  bool _hasShownBgError = false;
  bool _hasShownPhotoError = false;

  void _showNotificationSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = _sessionManager.getUser();

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          toolbarHeight: 64,
          backgroundColor: AppColors.primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          titleSpacing: 0,
          title: Text(
            l10n.ektm,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(child: Text('-')),
      );
    }

    final tahunAngkatan = user.angkatan?.toString().substring(0, 4) ?? DateTime.now().year.toString();
    final nimOnlyNumber = user.nim?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    final linkBgEktm = 'https://si-mona.uinsalatiga.ac.id/user_log/view_bg_ektm?angkatan=$tahunAngkatan';
    final linkProf =
        'https://si-mona.uinsalatiga.ac.id/user_log/view_profil_image_ektm?angkatan=$tahunAngkatan&nim=$nimOnlyNumber';

    final isMale = (user.jenisKelamin?.toUpperCase() ?? 'L') == 'L';
    final defaultPhotoAsset = isMale ? 'assets/images/defaultmale.jpg' : 'assets/images/defaultfemale.jpg';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Text(
          l10n.ektm,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: CustomScrollView(
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Top overflow background
                Positioned(
                  top: -600,
                  left: 0,
                  right: 0,
                  height: 600,
                  child: Container(color: AppColors.primary),
                ),
                // Curved primary background
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 120,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                    ),
                  ),
                ),

                // Main card content
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    children: [
                      // 1. Physical E-KTM Card
                      _buildEktmCard(
                        user: user,
                        l10n: l10n,
                        linkBgEktm: linkBgEktm,
                        linkProf: linkProf,
                        defaultPhotoAsset: defaultPhotoAsset,
                      ),

                      const SizedBox(height: 24),

                      // 2. Switcher Card for QR Code & Barcode
                      _buildCodeCard(
                        nim: user.nim ?? '',
                        l10n: l10n,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEktmCard({
    required dynamic user,
    required AppLocalizations l10n,
    required String linkBgEktm,
    required String linkProf,
    required String defaultPhotoAsset,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: AspectRatio(
          aspectRatio: 1.586, // Standard ID-1 card aspect ratio
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.22),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Image
                  Image.network(
                    linkBgEktm,
                    fit: BoxFit.fill,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: const Color(0xFFE2E8F0),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      if (!_hasShownBgError) {
                        _hasShownBgError = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _showNotificationSnackBar(l10n.failedConnectAcademicServer);
                        });
                      }
                      return Image.asset(
                        'assets/images/ktmdefault.jpg',
                        fit: BoxFit.fill,
                      );
                    },
                  ),

                  // Overlay Content with proportional LayoutBuilder
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = constraints.maxWidth;
                      final cardHeight = constraints.maxHeight;

                      final photoWidth = cardWidth * 0.175;
                      final photoHeight = photoWidth * (70 / 55);
                      final photoLeft = cardWidth * 0.035;
                      final photoBottom = cardHeight * 0.18;

                      final textLeft = photoLeft + photoWidth + (cardWidth * 0.025);
                      final textRight = cardWidth * 0.04;
                      final textBottom = photoBottom;

                      const textOutlines = [
                        Shadow(offset: Offset(-1, -1), color: Colors.white),
                        Shadow(offset: Offset(1, -1), color: Colors.white),
                        Shadow(offset: Offset(-1, 1), color: Colors.white),
                        Shadow(offset: Offset(1, 1), color: Colors.white),
                        Shadow(offset: Offset(0, -1), color: Colors.white),
                        Shadow(offset: Offset(0, 1), color: Colors.white),
                        Shadow(offset: Offset(-1, 0), color: Colors.white),
                        Shadow(offset: Offset(1, 0), color: Colors.white),
                      ];

                      final facultyName = (user.fakultas?.toString().trim().isNotEmpty ?? false)
                          ? '${l10n.facultyPrefix} ${user.fakultas?.toString().toUpperCase()}'
                          : '';
                      final prodiName = [
                        if (user.jenjang != null && user.jenjang.toString().isNotEmpty) user.jenjang.toString(),
                        if (user.programStudi != null && user.programStudi.toString().isNotEmpty)
                          user.programStudi.toString().toUpperCase(),
                      ].join(' - ');

                      return Stack(
                        children: [
                          // Student Photo
                          Positioned(
                            left: photoLeft,
                            bottom: photoBottom,
                            width: photoWidth,
                            height: photoHeight,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AnnouncementImageViewPage(
                                      imageUrl: linkProf,
                                      title: user.nama ?? l10n.ektm,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: Image.network(
                                    linkProf,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      if (!_hasShownPhotoError) {
                                        _hasShownPhotoError = true;
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          _showNotificationSnackBar(l10n.failedLoadKtmPhoto);
                                        });
                                      }
                                      return Image.asset(
                                        defaultPhotoAsset,
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Student Information Text
                          Positioned(
                            left: textLeft,
                            right: textRight,
                            bottom: textBottom,
                            height: photoHeight,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  user.nama?.toString().toUpperCase() ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: cardWidth * 0.030,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF002B49),
                                    shadows: textOutlines,
                                    height: 1.1,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                Text(
                                  user.nim?.toString().toUpperCase() ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: cardWidth * 0.028,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF002B49),
                                    shadows: textOutlines,
                                    height: 1.1,
                                  ),
                                ),
                                if (facultyName.isNotEmpty)
                                  Text(
                                    facultyName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: cardWidth * 0.026,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF003865),
                                      shadows: textOutlines,
                                      height: 1.1,
                                    ),
                                  ),
                                if (prodiName.isNotEmpty)
                                  Text(
                                    prodiName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: cardWidth * 0.026,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF003865),
                                      shadows: textOutlines,
                                      height: 1.1,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCodeCard({
    required String nim,
    required AppLocalizations l10n,
  }) {
    final isQr = _selectedType == EktmCodeType.qrCode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Segmented Switcher Buttons
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildToggleButton(
                    title: l10n.qrCode,
                    icon: Icons.qr_code_rounded,
                    isSelected: isQr,
                    onTap: () {
                      if (!isQr) {
                        setState(() => _selectedType = EktmCodeType.qrCode);
                      }
                    },
                  ),
                ),
                Expanded(
                  child: _buildToggleButton(
                    title: l10n.barcode,
                    icon: Icons.barcode_reader,
                    isSelected: !isQr,
                    onTap: () {
                      if (isQr) {
                        setState(() => _selectedType = EktmCodeType.barcode);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Code display area with animated switcher
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation), child: child),
            ),
            child: isQr
                ? Column(
                    key: const ValueKey('qr_view'),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                        ),
                        child: BarcodeWidget(
                          barcode: Barcode.qrCode(
                            errorCorrectLevel: BarcodeQRCorrectionLevel.high,
                          ),
                          data: nim,
                          width: 190,
                          height: 190,
                          drawText: false,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        nim,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  )
                : Container(
                    key: const ValueKey('barcode_view'),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                    ),
                    child: BarcodeWidget(
                      barcode: Barcode.code128(),
                      data: nim,
                      height: 90,
                      drawText: true,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: 28),

          // Security academic instruction notice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isQr ? l10n.useQrInstruction : l10n.useBarcodeInstruction,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primary : const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
