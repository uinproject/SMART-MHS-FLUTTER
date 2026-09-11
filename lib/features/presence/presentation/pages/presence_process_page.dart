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
  final ApiService _apiService = ApiService();
  final SessionManager _sessionManager = SessionManager();

  PresenceStep _currentStep = PresenceStep.validating;
  PresenceDetailData? _presenceDetail;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Gunakan Future.microtask untuk memicu pemanggilan API agar BuildContext siap
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
        title: Text(
          l10n.presenceProcessTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Header Card
            _buildStatusHeaderCard(l10n),
            const SizedBox(height: 20),

            // Detail Perkuliahan Card
            _buildLectureDetailCard(l10n),
            const SizedBox(height: 32),

            // Action Buttons
            _buildActionButtons(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeaderCard(AppLocalizations l10n) {
    switch (_currentStep) {
      case PresenceStep.validating:
        return _buildProgressCard(
          icon: const SpinKitThreeBounce(color: AppColors.primary, size: 28),
          title: l10n.validatingPresenceCode,
          subtitle: l10n.pleaseWait,
          color: AppColors.primary,
        );
      case PresenceStep.recording:
        return _buildProgressCard(
          icon: const SpinKitThreeBounce(color: AppColors.primary, size: 28),
          title: l10n.recordingPresence,
          subtitle: l10n.pleaseWait,
          color: AppColors.primary,
        );
      case PresenceStep.success:
        return _buildResultCard(
          icon: Icons.check_circle_rounded,
          iconColor: AppColors.success,
          title: l10n.presenceSuccess,
          message: l10n.presenceSuccessDetail,
          backgroundColor: AppColors.success.withValues(alpha: 0.1),
          borderColor: AppColors.success.withValues(alpha: 0.3),
        );
      case PresenceStep.alreadyRecorded:
        return _buildResultCard(
          icon: Icons.verified_rounded,
          iconColor: AppColors.primary,
          title: l10n.presenceSuccess,
          message: l10n.presenceAlreadyRecorded,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          borderColor: AppColors.primary.withValues(alpha: 0.3),
        );
      case PresenceStep.failed:
        return _buildResultCard(
          icon: Icons.cancel_rounded,
          iconColor: AppColors.danger,
          title: l10n.presenceFailed,
          message: _errorMessage.isNotEmpty ? _errorMessage : l10n.systemError,
          backgroundColor: AppColors.danger.withValues(alpha: 0.08),
          borderColor: AppColors.danger.withValues(alpha: 0.25),
        );
    }
  }

  Widget _buildProgressCard({
    required Widget icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          icon,
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: color,
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
        ],
      ),
    );
  }

  Widget _buildResultCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 52),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
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
                    Icons.school_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.courseInfo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (detail != null && detail.pertemuanKe.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.meetingNumber(detail.pertemuanKe),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
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
                  // Mata Kuliah
                  Text(
                    detail.mataKuliah.isNotEmpty ? detail.mataKuliah : '-',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Dosen
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          detail.dosen.isNotEmpty ? detail.dosen : '-',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Judul / Topik
                  if (detail.judulKuliah.isNotEmpty) ...[
                    _buildInfoRow(
                      label: l10n.lectureTopic,
                      value: detail.judulKuliah,
                      icon: Icons.title_rounded,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Deskripsi
                  if (detail.isiKuliah.isNotEmpty) ...[
                    _buildInfoRow(
                      label: l10n.lectureDescription,
                      value: detail.isiKuliah,
                      icon: Icons.notes_rounded,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Ruangan & Waktu
                  Row(
                    children: [
                      if (detail.ruang.isNotEmpty)
                        Expanded(
                          child: _buildInfoBadge(
                            icon: Icons.meeting_room_outlined,
                            label: l10n.room,
                            value: detail.ruang,
                          ),
                        ),
                      if (detail.ruang.isNotEmpty && detail.jam.isNotEmpty)
                        const SizedBox(width: 12),
                      if (detail.jam.isNotEmpty)
                        Expanded(
                          child: _buildInfoBadge(
                            icon: Icons.access_time_rounded,
                            label: l10n.time,
                            value: detail.jam,
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

  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBadge({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
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
          _buildShimmerBox(width: double.infinity, height: 20),
          const SizedBox(height: 10),
          _buildShimmerBox(width: 180, height: 14),
          const SizedBox(height: 18),
          _buildShimmerBox(width: double.infinity, height: 14),
          const SizedBox(height: 8),
          _buildShimmerBox(width: 220, height: 14),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildShimmerBox(width: double.infinity, height: 48)),
              const SizedBox(width: 12),
              Expanded(child: _buildShimmerBox(width: double.infinity, height: 48)),
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
        borderRadius: BorderRadius.circular(8),
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
          ElevatedButton.icon(
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
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: Colors.grey.shade400),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
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
    return ElevatedButton.icon(
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
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 2,
      ),
    );
  }
}
