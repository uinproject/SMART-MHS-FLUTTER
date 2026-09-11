import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:smartmahsiswaflutter/core/network/api_service.dart';
import 'package:smartmahsiswaflutter/core/storage/session_manager.dart';
import 'package:smartmahsiswaflutter/core/theme/app_colors.dart';
import 'package:smartmahsiswaflutter/core/utils/subscription_gate.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../data/models/attendance_courses_response.dart';
import 'attendance_course_detail_page.dart';

enum _CoursesPageState { loading, success, error }

class AttendanceCoursesPage extends StatefulWidget {
  const AttendanceCoursesPage({super.key});

  @override
  State<AttendanceCoursesPage> createState() => _AttendanceCoursesPageState();
}

class _AttendanceCoursesPageState extends State<AttendanceCoursesPage> {
  static const LinearGradient _mainGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF003D82), Color(0xFF0056B3)],
  );

  final ApiService _apiService = ApiService();
  final SessionManager _sessionManager = SessionManager();
  final TextEditingController _searchController = TextEditingController();

  _CoursesPageState _state = _CoursesPageState.loading;
  List<AttendanceCourseItem> _allCourses = [];
  List<AttendanceCourseItem> _filteredCourses = [];
  String _errorMessage = '';
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    // Gunakan Future.microtask untuk memicu pemanggilan API dan subscription check
    Future.microtask(() {
      if (!mounted) return;
      checkSubscription(context, SubscriptionGateFeatures.attendance);
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _state = _CoursesPageState.loading;
      _errorMessage = '';
    });

    final user = _sessionManager.getUser();
    final nim = user?.nim ?? '';
    final lang = _sessionManager.getLocale();

    if (nim.isEmpty) {
      if (mounted) {
        setState(() {
          _state = _CoursesPageState.error;
          _errorMessage = 'Sesi login tidak valid.';
        });
      }
      return;
    }

    try {
      final response = await _apiService.getAttendanceCourses(
        nim: nim,
        language: lang,
      );

      if (!mounted) return;

      if (response.success && response.data.isNotEmpty) {
        setState(() {
          _allCourses = response.data;
          _filterCourses(_searchController.text);
          _state = _CoursesPageState.success;
        });
      } else if (response.success && response.data.isEmpty) {
        setState(() {
          _allCourses = [];
          _filteredCourses = [];
          _state = _CoursesPageState.success;
        });
      } else {
        setState(() {
          _state = _CoursesPageState.error;
          _errorMessage = response.message?.isNotEmpty == true
              ? response.message!
              : 'Gagal memuat riwayat kehadiran';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _CoursesPageState.error;
        _errorMessage = e.toString();
      });
    }
  }

  void _filterCourses(String query) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      _filteredCourses = List.from(_allCourses);
    } else {
      _filteredCourses = _allCourses.where((item) {
        final makulMatch = item.makul.toLowerCase().contains(cleanQuery);
        final kodeMatch = item.kdMakul.toLowerCase().contains(cleanQuery);
        final dosenMatch = item.dosen.toLowerCase().contains(cleanQuery);
        return makulMatch || kodeMatch || dosenMatch;
      }).toList();
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
        title: _isSearchExpanded
            ? Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    hintText: l10n.searchCourseHint,
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.cancel_rounded, size: 18, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _filterCourses('');
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _filterCourses(val);
                    });
                  },
                ),
              )
            : Text(
                l10n.attendanceTitle,
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
          IconButton(
            icon: Icon(
              _isSearchExpanded ? Icons.close_rounded : Icons.search_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                if (_isSearchExpanded) {
                  _isSearchExpanded = false;
                  _searchController.clear();
                  _filterCourses('');
                } else {
                  _isSearchExpanded = true;
                }
              });
            },
          ),
          const SizedBox(width: 8),
        ],
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
      case _CoursesPageState.loading:
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.35),
            const Center(
              child: SpinKitThreeBounce(color: AppColors.primary, size: 30),
            ),
          ],
        );
      case _CoursesPageState.error:
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
                    child: const Icon(Icons.cloud_off_rounded, color: AppColors.danger, size: 48),
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
      case _CoursesPageState.success:
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            // 1. Card Ringkasan Total Persentase Kehadiran (User Requirement #1)
            _buildOverallSummaryHeroCard(l10n),
            const SizedBox(height: 18),

            // 2. Kotak Search Modern
            _buildModernSearchBox(l10n),
            const SizedBox(height: 22),

            // 3. Section Label
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.class_rounded, size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.totalCourses,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_filteredCourses.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 3. List of Courses
            if (_filteredCourses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        l10n.noCoursesFound,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(_filteredCourses.length, (index) {
                final course = _filteredCourses[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildCourseCard(course, l10n),
                );
              }),
          ],
        );
    }
  }

  /// Hero Card for Overall Attendance Percentage (Requirement #1)
  Widget _buildOverallSummaryHeroCard(AppLocalizations l10n) {
    int totalPertemuan = 0;
    int totalKehadiran = 0;

    for (final c in _allCourses) {
      totalPertemuan += c.jumlahPertemuan;
      totalKehadiran += c.jumlahKehadiran;
    }

    final double overallPercentage = totalPertemuan > 0
        ? ((totalKehadiran * 100) / totalPertemuan)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: _mainGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.overallAttendanceSummary,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${overallPercentage.toStringAsFixed(1)} %',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (overallPercentage >= 75.0 ? AppColors.success : (overallPercentage >= 50.0 ? AppColors.secondary : AppColors.danger)).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      overallPercentage >= 75.0 ? Icons.check_circle_rounded : Icons.info_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      overallPercentage >= 75.0 ? 'Baik' : 'Perhatian',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryStatItem(
                    label: l10n.totalCourses,
                    value: '${_allCourses.length}',
                  ),
                ),
                Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.2)),
                Expanded(
                  child: _buildSummaryStatItem(
                    label: l10n.totalMeetings,
                    value: '$totalPertemuan',
                  ),
                ),
                Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.2)),
                Expanded(
                  child: _buildSummaryStatItem(
                    label: l10n.totalAttendance,
                    value: '$totalKehadiran',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStatItem({required String label, required String value}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  /// Modern Search Box in Body
  Widget _buildModernSearchBox(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          hintText: l10n.searchCourseHint,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.primary,
            size: 22,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.cancel_rounded, color: Colors.grey, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _filterCourses('');
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (val) {
          setState(() {
            _filterCourses(val);
          });
        },
      ),
    );
  }

  /// Course Card in List
  Widget _buildCourseCard(AttendanceCourseItem course, AppLocalizations l10n) {
    final double percent = double.tryParse(course.presentase.replaceAll('%', '').trim()) ??
        (course.jumlahPertemuan > 0 ? (course.jumlahKehadiran * 100 / course.jumlahPertemuan) : 0.0);

    Color percentColor = AppColors.success;
    if (percent < 50.0) {
      percentColor = AppColors.danger;
    } else if (percent < 75.0) {
      percentColor = AppColors.secondary;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AttendanceCourseDetailPage(course: course),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Code & SKS Chip
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        course.kdMakul,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (course.kelas.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Kls ${course.kelas}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: percentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${percent.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: percentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Course Name
                Text(
                  course.makul,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Lecturer Row
                Row(
                  children: [
                    ClipOval(
                      child: Container(
                        width: 28,
                        height: 28,
                        color: Colors.grey.shade100,
                        child: course.urlFotoDosen.isNotEmpty
                            ? Image.network(
                                course.urlFotoDosen,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, size: 18, color: Colors.grey),
                              )
                            : const Icon(Icons.person_rounded, size: 18, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        course.dosen,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Schedule and Room
                Row(
                  children: [
                    if (course.hari.isNotEmpty || course.jam.isNotEmpty)
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.schedule_rounded, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '${course.hari}${course.jam.isNotEmpty ? ', ${course.jam}' : ''}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (course.ruang.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          Icon(Icons.meeting_room_outlined, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            course.ruang,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: course.jumlahPertemuan > 0
                        ? (course.jumlahKehadiran / course.jumlahPertemuan).clamp(0.0, 1.0)
                        : (percent / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(percentColor),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),

                // Attendance count and chevron
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${course.jumlahKehadiran} / ${course.jumlahPertemuan} ${l10n.present}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          l10n.attendanceDetailTitle,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: AppColors.primary,
                        ),
                      ],
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
