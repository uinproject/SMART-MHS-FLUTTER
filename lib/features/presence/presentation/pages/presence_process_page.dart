import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:smartmahsiswaflutter/core/network/api_service.dart';
import 'package:smartmahsiswaflutter/core/storage/session_manager.dart';
import 'package:smartmahsiswaflutter/core/theme/app_colors.dart';
import 'package:smartmahsiswaflutter/core/utils/device_utils.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import 'package:smartmahsiswaflutter/features/presence/data/models/presence_verification_response.dart';

enum PresenceStep {
  validating,
  recording,
  success,
  alreadyRecorded,
  failed,
}

class PresenceProcessPage extends StatefulWidget {
  final String? qrCode;
  final String? shortCode;

  const PresenceProcessPage({
    super.key,
    this.qrCode,
    this.shortCode,
  });

  @override
  State<PresenceProcessPage> createState() => _PresenceProcessPageState();
}

class _PresenceProcessPageState extends State<PresenceProcessPage> {
  static const LinearGradient _mainGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF003D82), Color(0xFF0056B3)],
  );

  final ApiService _apiService = ApiService();
  final SessionManager _sessionManager = SessionManager();

  PresenceStep _currentStep = PresenceStep.validating;
  PresenceDetailData? _presenceDetail;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _processPresence();
    });
  }

  Future<void> _processPresence() async {
    if (!mounted) return;

    setState(() {
      _currentStep = PresenceStep.validating;
      _errorMessage = '';
    });

    final user = _sessionManager.getUser();
    final nim = user?.nim ?? '';
    final lang = _sessionManager.getLocale();

    if (nim.isEmpty) {
      if (mounted) {
        setState(() {
          _currentStep = PresenceStep.failed;
          _errorMessage = 'Sesi pengguna tidak valid. Silakan login kembali.';
        });
      }
      return;
    }

    try {
      // 1. Verifikasi QR Code atau Short Code
      PresenceVerificationResponse verifResult;
      if (widget.qrCode != null && widget.qrCode!.isNotEmpty) {
        verifResult = await _apiService.verifyPresenceQr(
          nim: nim,
          qrKey: widget.qrCode!,
          language: lang,
        );
      } else if (widget.shortCode != null && widget.shortCode!.isNotEmpty) {
        verifResult = await _apiService.verifyPresenceShortCode(
          nim: nim,
          shortCode: widget.shortCode!,
          language: lang,
        );
      } else {
        if (mounted) {
          setState(() {
            _currentStep = PresenceStep.failed;
            _errorMessage = 'Kode QR atau Short Code tidak ditemukan';
          });
        }
        return;
      }

      if (!mounted) return;

      if (!verifResult.success || verifResult.data == null) {
        setState(() {
          _currentStep = PresenceStep.failed;
          _errorMessage = verifResult.message.isNotEmpty
              ? verifResult.message
              : 'Verifikasi kode presensi gagal';
        });
        return;
      }

      final detail = verifResult.data!;
      setState(() {
        _presenceDetail = detail;
      });

      // 2. Cek apakah sudah pernah presensi sebelumnya
      if (detail.statusabsen) {
        setState(() {
          _currentStep = PresenceStep.alreadyRecorded;
        });
        return;
      }

      // 3. Simpan Presensi (saveabsloc) tanpa verifikasi GPS (bypassed)
      setState(() {
        _currentStep = PresenceStep.recording;
      });

      final deviceId = await DeviceUtils.getDeviceId();
      final saveResult = await _apiService.savePresence(
        nim: nim,
        idAbsensi: detail.idabsensi,
        pertemuanKe: detail.pertemuanKe,
        idDevice: deviceId,
        fakeLoc: 'false',
      );

      if (!mounted) return;

      if (saveResult.success) {
        setState(() {
          _currentStep = PresenceStep.success;
        });
      } else {
        setState(() {
          _currentStep = PresenceStep.failed;
          _errorMessage = saveResult.message.isNotEmpty
              ? saveResult.message
              : 'Gagal mencatat presensi';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentStep = PresenceStep.failed;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.presenceProcessTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Hero Card
            _buildHeroStatusCard(l10n),
            const SizedBox(height: 24),

            // Section Label
            _buildSectionLabel(
              l10n.courseInfo,
              Icons.school_rounded,
              AppColors.primary,
            ),
            const SizedBox(height: 12),

            // Lecture Detail Card
            _buildLectureDetailCard(l10n),
            const SizedBox(height: 28),

            // Action Buttons
            _buildActionButtons(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroStatusCard(AppLocalizations l10n) {
    switch (_currentStep) {
      case PresenceStep.validating:
        return _buildProgressHeroCard(
          title: l10n.validatingPresenceCode,
          subtitle: l10n.pleaseWait,
          stepText: '1 / 2',
        );
      case PresenceStep.recording:
        return _buildProgressHeroCard(
          title: l10n.recordingPresence,
          subtitle: l10n.pleaseWait,
          stepText: '2 / 2',
        );
      case PresenceStep.success:
        return _buildResultHeroCard(
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF0F766E), Color(0xFF059669)],
          ),
          shadowColor: const Color(0xFF059669),
          icon: Icons.check_circle_rounded,
          title: l10n.presenceSuccess,
          message: l10n.presenceSuccessDetail,
        );
      case PresenceStep.alreadyRecorded:
        return _buildResultHeroCard(
          gradient: _mainGradient,
          shadowColor: AppColors.primary,
          icon: Icons.verified_rounded,
          title: l10n.presenceSuccess,
          message: l10n.presenceAlreadyRecorded,
        );
      case PresenceStep.failed:
        return _buildResultHeroCard(
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFFB91C1C), Color(0xFFDC2626)],
          ),
          shadowColor: const Color(0xFFDC2626),
          icon: Icons.cancel_rounded,
          title: l10n.presenceFailed,
          message: _errorMessage.isNotEmpty ? _errorMessage : l10n.systemError,
        );
    }
  }

  Widget _buildProgressHeroCard({
    required String title,
    required String subtitle,
    required String stepText,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const SpinKitThreeBounce(color: AppColors.primary, size: 30),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Step $stepText',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultHeroCard({
    required LinearGradient gradient,
    required Color shadowColor,
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.32),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 38),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLectureDetailCard(AppLocalizations l10n) {
    final detail = _presenceDetail;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card with meeting number badge
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail?.mataKuliah.isNotEmpty == true
                            ? detail!.mataKuliah
                            : (detail == null ? 'Memuat data...' : '-'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (detail != null && detail.dosen.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          detail.dosen,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (detail != null && detail.pertemuanKe.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: _mainGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      l10n.meetingNumber(detail.pertemuanKe),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

          // Body Details or Shimmer
          if (detail == null)
            _buildDetailShimmer()
          else
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul / Topik Perkuliahan
                  if (detail.judulKuliah.isNotEmpty) ...[
                    _buildModernInfoTile(
                      label: l10n.lectureTopic,
                      value: detail.judulKuliah,
                      icon: Icons.title_rounded,
                      accentColor: AppColors.primary,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Deskripsi
                  if (detail.isiKuliah.isNotEmpty) ...[
                    _buildModernInfoTile(
                      label: l10n.lectureDescription,
                      value: detail.isiKuliah,
                      icon: Icons.notes_rounded,
                      accentColor: AppColors.secondary,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Ruangan & Waktu Badges
                  Row(
                    children: [
                      if (detail.ruang.isNotEmpty)
                        Expanded(
                          child: _buildInfoBadge(
                            icon: Icons.meeting_room_rounded,
                            label: l10n.room,
                            value: detail.ruang,
                            iconColor: AppColors.primary,
                          ),
                        ),
                      if (detail.ruang.isNotEmpty && detail.jam.isNotEmpty)
                        const SizedBox(width: 12),
                      if (detail.jam.isNotEmpty)
                        Expanded(
                          child: _buildInfoBadge(
                            icon: Icons.access_time_filled_rounded,
                            label: l10n.time,
                            value: detail.jam,
                            iconColor: AppColors.secondary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernInfoTile({
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailShimmer() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerBox(width: double.infinity, height: 18),
          const SizedBox(height: 10),
          _buildShimmerBox(width: 180, height: 14),
          const SizedBox(height: 18),
          _buildShimmerBox(width: double.infinity, height: 56),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildShimmerBox(width: double.infinity, height: 50)),
              const SizedBox(width: 12),
              Expanded(child: _buildShimmerBox(width: double.infinity, height: 50)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBox({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n) {
    if (_currentStep == PresenceStep.validating || _currentStep == PresenceStep.recording) {
      return const SizedBox.shrink();
    }

    if (_currentStep == PresenceStep.failed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
              onPressed: _processPresence,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: Text(
                l10n.retryPresence,
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
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              l10n.cancel,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      );
    }

    // Success or Already Recorded
    return Container(
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
          Navigator.popUntil(context, (route) => route.isFirst);
        },
        icon: const Icon(Icons.home_rounded, color: Colors.white),
        label: Text(
          l10n.backToHome,
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
    );
  }
}
