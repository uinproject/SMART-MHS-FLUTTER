import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:open_filex/open_filex.dart';
import 'package:smartmahsiswaflutter/core/network/api_service.dart';
import 'package:smartmahsiswaflutter/core/storage/session_manager.dart';
import 'package:smartmahsiswaflutter/core/theme/app_colors.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../data/models/attendance_detail_response.dart';

enum _MeetingDetailState { loading, success, error }

class AttendanceMeetingDetailPage extends StatefulWidget {
  final String idAbsensi;
  final int pertemuanKe;
  final String kodeMakul;
  final int semester;
  final String mataKuliah;
  final String dosen;

  const AttendanceMeetingDetailPage({
    super.key,
    required this.idAbsensi,
    required this.pertemuanKe,
    required this.kodeMakul,
    required this.semester,
    required this.mataKuliah,
    required this.dosen,
  });

  @override
  State<AttendanceMeetingDetailPage> createState() => _AttendanceMeetingDetailPageState();
}

class _AttendanceMeetingDetailPageState extends State<AttendanceMeetingDetailPage> {
  static const LinearGradient _mainGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF003D82), Color(0xFF0056B3)],
  );

  final ApiService _apiService = ApiService();
  final SessionManager _sessionManager = SessionManager();

  _MeetingDetailState _state = _MeetingDetailState.loading;
  AttendanceMeetingDetail? _detail;
  String _errorMessage = '';

  // Download state map for each material: {fileName: progressDouble}
  final Map<String, double> _downloadProgress = {};
  final Map<String, String> _downloadedPaths = {};
  final Map<String, bool> _isDownloading = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadData());
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _state = _MeetingDetailState.loading;
      _errorMessage = '';
    });

    final user = _sessionManager.getUser();
    final nim = user?.nim ?? '';
    final lang = _sessionManager.getLocale();

    if (nim.isEmpty) {
      if (mounted) {
        setState(() {
          _state = _MeetingDetailState.error;
          _errorMessage = 'Sesi pengguna tidak valid.';
        });
      }
      return;
    }

    try {
      final response = await _apiService.getAttendanceDetailMeeting(
        nim: nim,
        semester: widget.semester,
        idAbsensi: widget.idAbsensi,
        kodeMk: widget.kodeMakul,
        pertemuanKe: widget.pertemuanKe,
        language: lang,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _detail = response.data;
          _state = _MeetingDetailState.success;
        });
      } else {
        setState(() {
          _state = _MeetingDetailState.error;
          _errorMessage = response.message?.isNotEmpty == true
              ? response.message!
              : 'Gagal memuat detail pertemuan';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _MeetingDetailState.error;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _downloadMaterial(AttendanceMaterialItem material) async {
    final fileName = material.namaFile.isNotEmpty
        ? material.namaFile
        : 'materi_p${widget.pertemuanKe}_${widget.kodeMakul}.pdf';

    setState(() {
      _isDownloading[fileName] = true;
      _downloadProgress[fileName] = 0.0;
    });

    try {
      final savedPath = await _apiService.downloadMaterialFile(
        url: material.link,
        fileName: fileName,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() {
              _downloadProgress[fileName] = received / total;
            });
          }
        },
      );

      if (!mounted) return;

      setState(() {
        _isDownloading[fileName] = false;
        _downloadProgress[fileName] = 1.0;
        _downloadedPaths[fileName] = savedPath;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${material.judul}: Download selesai'),
          action: SnackBarAction(
            label: 'Buka',
            onPressed: () {
              OpenFilex.open(savedPath);
            },
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDownloading[fileName] = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengunduh: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: const Color(0xFF003D82),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.meetingDetailTitle,
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
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: _buildBody(l10n),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    switch (_state) {
      case _MeetingDetailState.loading:
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.35),
            const Center(
              child: SpinKitThreeBounce(color: AppColors.primary, size: 30),
            ),
          ],
        );
      case _MeetingDetailState.error:
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.22),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 48),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage.isNotEmpty ? _errorMessage : l10n.failedLoadData,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    label: Text(l10n.retryPresence, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case _MeetingDetailState.success:
        final detail = _detail!;
        final bool isPresent = detail.isPresent;

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            // 1. Hero Status Card (Hadir / Tidak Hadir)
            _buildStatusHeroCard(detail, isPresent, l10n),
            const SizedBox(height: 20),

            // 2. Info Mata Kuliah & Jadwal
            _buildCourseInfoCard(detail, l10n),
            const SizedBox(height: 20),

            // 3. Topik & Deskripsi Perkuliahan
            _buildTopicContentCard(detail, l10n),
            const SizedBox(height: 24),

            // 4. Section: Materi Perkuliahan
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.folder_shared_rounded, size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.lectureMaterials,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (detail.materiFile.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${detail.materiFile.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // 5. Material List / Empty state
            if (detail.materiFile.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.cloud_off_rounded, size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 10),
                      Text(
                        l10n.noMaterials,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(detail.materiFile.length, (index) {
                final mat = detail.materiFile[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildMaterialCard(mat, l10n),
                );
              }),
          ],
        );
    }
  }

  Widget _buildStatusHeroCard(AttendanceMeetingDetail detail, bool isPresent, AppLocalizations l10n) {
    final gradient = isPresent
        ? const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF0F766E), Color(0xFF059669)],
          )
        : const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFFB91C1C), Color(0xFFDC2626)],
          );

    final shadowColor = isPresent ? const Color(0xFF059669) : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPresent ? l10n.present : l10n.absent,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.meetingNumber('${detail.pertemuanKe}'),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseInfoCard(AttendanceMeetingDetail detail, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.mataKuliah.isNotEmpty ? detail.mataKuliah : widget.mataKuliah,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  detail.dosen.isNotEmpty ? detail.dosen : widget.dosen,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (detail.waktu.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time_rounded, size: 15, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    detail.waktu,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopicContentCard(AttendanceMeetingDetail detail, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topic
          Row(
            children: [
              const Icon(Icons.title_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                l10n.lectureTopic,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            detail.judul.isNotEmpty ? detail.judul : '-',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),

          // Description / Material summary
          Row(
            children: [
              const Icon(Icons.notes_rounded, size: 16, color: AppColors.secondary),
              const SizedBox(width: 8),
              Text(
                l10n.lectureDescription,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            detail.isi.isNotEmpty ? detail.isi : '-',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialCard(AttendanceMaterialItem material, AppLocalizations l10n) {
    final fileName = material.namaFile.isNotEmpty
        ? material.namaFile
        : 'materi_p${widget.pertemuanKe}_${widget.kodeMakul}.pdf';

    final bool isDownloading = _isDownloading[fileName] == true;
    final double progress = _downloadProgress[fileName] ?? 0.0;
    final String? downloadedPath = _downloadedPaths[fileName];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.description_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        material.judul.isNotEmpty ? material.judul : fileName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fileName,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Download Progress Bar if downloading
            if (isDownloading) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.downloadingMaterial,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Action Button: Download or Open File
            if (downloadedPath != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    OpenFilex.open(downloadedPath);
                  },
                  icon: const Icon(Icons.file_open_rounded, size: 18, color: Colors.white),
                  label: Text(
                    l10n.openFile,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isDownloading ? null : () => _downloadMaterial(material),
                  icon: const Icon(Icons.download_rounded, size: 18, color: Colors.white),
                  label: Text(
                    l10n.downloadMaterial,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
