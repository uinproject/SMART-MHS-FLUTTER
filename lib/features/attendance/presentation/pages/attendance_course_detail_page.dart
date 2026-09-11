import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:smartmahsiswaflutter/core/network/api_service.dart';
import 'package:smartmahsiswaflutter/core/storage/session_manager.dart';
import 'package:smartmahsiswaflutter/core/theme/app_colors.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../data/models/attendance_courses_response.dart';
import '../../data/models/attendance_list_response.dart';
import 'attendance_meeting_detail_page.dart';

enum _CourseDetailState { loading, success, error }

class AttendanceCourseDetailPage extends StatefulWidget {
  final AttendanceCourseItem course;

  const AttendanceCourseDetailPage({
    super.key,
    required this.course,
  });

  @override
  State<AttendanceCourseDetailPage> createState() => _AttendanceCourseDetailPageState();
}

class _AttendanceCourseDetailPageState extends State<AttendanceCourseDetailPage> {
  static const LinearGradient _mainGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF003D82), Color(0xFF0056B3)],
  );

  final ApiService _apiService = ApiService();
  final SessionManager _sessionManager = SessionManager();

  _CourseDetailState _state = _CourseDetailState.loading;
  List<AttendanceHistoryItem> _meetings = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadData());
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _state = _CourseDetailState.loading;
      _errorMessage = '';
    });

    final user = _sessionManager.getUser();
    final nim = user?.nim ?? '';
    final lang = _sessionManager.getLocale();

    if (nim.isEmpty) {
      if (mounted) {
        setState(() {
          _state = _CourseDetailState.error;
          _errorMessage = 'Sesi pengguna tidak valid.';
        });
      }
      return;
    }

    try {
      final response = await _apiService.getAttendanceListPerCourse(
        nim: nim,
        semester: widget.course.semester,
        idAbsensi: widget.course.idAbsensi,
        kodeMk: widget.course.kdMakul,
        language: lang,
      );

      if (!mounted) return;

      if (response.success && response.data.isNotEmpty) {
        setState(() {
          _meetings = response.data;
          _state = _CourseDetailState.success;
        });
      } else if (response.success && response.data.isEmpty) {
        setState(() {
          _meetings = [];
          _state = _CourseDetailState.success;
        });
      } else {
        setState(() {
          _state = _CourseDetailState.error;
          _errorMessage = response.message?.isNotEmpty == true
              ? response.message!
              : 'Gagal memuat rincian daftar hadir';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _CourseDetailState.error;
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
        backgroundColor: const Color(0xFF003D82),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.attendanceDetailTitle,
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
      case _CourseDetailState.loading:
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.35),
            const Center(
              child: SpinKitThreeBounce(color: AppColors.primary, size: 30),
            ),
          ],
        );
      case _CourseDetailState.error:
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
      case _CourseDetailState.success:
        int totalPertemuan = _meetings.length;
        int totalHadir = _meetings.where((m) => m.isPresent).length;
        double percentage = totalPertemuan > 0 ? (totalHadir * 100 / totalPertemuan) : 0.0;

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            // Course Info Header Card
            _buildCourseHeaderCard(totalPertemuan, totalHadir, percentage, l10n),
            const SizedBox(height: 24),

            // Section Label
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.event_note_rounded, size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  '${l10n.totalMeetings} (${_meetings.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // List of Meetings
            if (_meetings.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'Belum ada riwayat pertemuan perkuliahan',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              ...List.generate(_meetings.length, (index) {
                final meeting = _meetings[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildMeetingItemCard(meeting, l10n),
                );
              }),
          ],
        );
    }
  }

  Widget _buildCourseHeaderCard(int totalPertemuan, int totalHadir, double percentage, AppLocalizations l10n) {
    Color badgeColor = percentage >= 75.0
        ? AppColors.success
        : (percentage >= 50.0 ? AppColors.secondary : AppColors.danger);

    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.course.kdMakul,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.course.makul,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Circular / Pill Percentage
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                    Text(
                      l10n.present,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Lecturer row
          Row(
            children: [
              ClipOval(
                child: Container(
                  width: 32,
                  height: 32,
                  color: Colors.grey.shade100,
                  child: widget.course.urlFotoDosen.isNotEmpty
                      ? Image.network(
                          widget.course.urlFotoDosen,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, size: 20, color: Colors.grey),
                        )
                      : const Icon(Icons.person_rounded, size: 20, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.course.dosen,
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
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Quick statistics: Pertemuan & Hadir
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  label: l10n.totalMeetings,
                  value: '$totalPertemuan',
                  icon: Icons.calendar_today_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMiniStat(
                  label: l10n.totalAttendance,
                  value: '$totalHadir',
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMiniStat(
                  label: l10n.absent,
                  value: '${totalPertemuan - totalHadir}',
                  icon: Icons.cancel_outlined,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingItemCard(AttendanceHistoryItem meeting, AppLocalizations l10n) {
    final bool isPresent = meeting.isPresent;
    final Color statusColor = isPresent ? AppColors.success : AppColors.danger;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AttendanceMeetingDetailPage(
                  idAbsensi: meeting.idAbsensi,
                  pertemuanKe: meeting.pertemuanKe,
                  kodeMakul: meeting.kodeMakul,
                  semester: meeting.semester,
                  mataKuliah: widget.course.makul,
                  dosen: widget.course.dosen,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Meeting number badge
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: _mainGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'P${meeting.pertemuanKe}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meeting.judul.isNotEmpty ? meeting.judul : l10n.meetingNumber('${meeting.pertemuanKe}'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (meeting.isi.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          meeting.isi,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Status Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            size: 13,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPresent ? l10n.present : l10n.absent,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
