import 'dart:io';
import 'package:dio/dio.dart' show DioException, DioExceptionType;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/session_manager.dart';
import '../../../../core/utils/app_notifications.dart';
import '../../../home/data/models/jadwal_response.dart';
import '../../../bills/presentation/widgets/error_state_widget.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

/// Load states — same pattern as the KRS/EDOM/bills pages:
/// success / noData / serverMessage (API answered with a status+message,
/// informational) / serverError (API-level failure) / noInternet.
enum _ScheduleLoadState {
  loading,
  success,
  noData,
  serverMessage,
  serverError,
  noInternet,
}

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF003D82), Color(0xFF0056B3)],
  );

  final _apiService = ApiService();
  final _sessionManager = SessionManager();
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _dayKeys = {};

  JadwalResponse? _jadwal;
  _ScheduleLoadState _state = _ScheduleLoadState.loading;

  /// Failure detail resolved by priority: server `message` → concrete cause
  /// ("Error 500" / network) → localized general message.
  String? _errorMessage;
  int _selectedSemester = 0;
  int _originalSemester = 0;

  @override
  void initState() {
    super.initState();
    final user = _sessionManager.getUser();
    if (user != null) {
      _selectedSemester = user.semester ?? 1;
      _originalSemester = _selectedSemester;
      Future.microtask(() => _loadJadwal());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadJadwal({bool showFullLoading = true}) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    if (showFullLoading) {
      setState(() => _state = _ScheduleLoadState.loading);
    }

    final user = _sessionManager.getUser();
    if (user == null) {
      if (mounted) {
        setState(() {
          _state = _ScheduleLoadState.serverError;
          _errorMessage = l10n.errorResponseApi;
        });
      }
      return;
    }

    try {
      final result = await _apiService.getJadwalmhs(
        nim: user.nim ?? '',
        semester: _selectedSemester,
      );

      if (!mounted) return;
      setState(() {
        _jadwal = result;
        if (result != null && result.success && result.data != null) {
          _state = result.data!.isEmpty
              ? _ScheduleLoadState.noData
              : _ScheduleLoadState.success;
        } else if (result != null &&
            result.message != null &&
            result.message!.isNotEmpty) {
          // The API ANSWERED with a status + message — informational, shown
          // with the regular (calendar) icon, not the error icon.
          _state = _ScheduleLoadState.serverMessage;
          _errorMessage = result.message;
        } else if (result != null) {
          // success=false without a message — connection-level failure.
          _state = _ScheduleLoadState.noInternet;
        } else {
          _state = _ScheduleLoadState.serverError;
          _errorMessage = l10n.errorResponseApi;
        }
      });

      if (_state == _ScheduleLoadState.success &&
          _selectedSemester == _originalSemester) {
        _scrollToToday();
      }
    } catch (e) {
      // The API service rethrows — describe the concrete cause.
      if (!mounted) return;
      setState(() {
        if (e is DioException) {
          switch (e.type) {
            case DioExceptionType.connectionTimeout:
            case DioExceptionType.sendTimeout:
            case DioExceptionType.receiveTimeout:
            case DioExceptionType.connectionError:
              _state = _ScheduleLoadState.noInternet;
            case DioExceptionType.badResponse:
              final code = e.response?.statusCode;
              _state = _ScheduleLoadState.serverError;
              _errorMessage = code != null
                  ? 'Error $code'
                  : l10n.errorResponseApi;
            default:
              _state = _ScheduleLoadState.serverError;
              _errorMessage = l10n.errorResponseApi;
          }
        } else {
          _state = _ScheduleLoadState.serverError;
          _errorMessage = l10n.errorResponseApi;
        }
      });
    }
  }

  /// Auto-scroll ke jadwal hari ini (legacy behaviour).
  ///
  /// Waits until the list frame is built, then ensures today's section is
  /// visible. [Scrollable.ensureVisible] needs the target to actually be
  /// BUILT — lazy lists only build visible items — so the success list uses
  /// a large cacheExtent (see [build]) and this retries once on the next
  /// frame if the context is somehow still missing.
  void _scrollToToday() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _tryScrollToToday(retry: true),
    );
  }

  void _tryScrollToToday({bool retry = false}) {
    if (!mounted) return;
    final today = DateFormat('EEEE', 'id_ID').format(DateTime.now());
    int? targetIndex;

    if (_jadwal?.data != null) {
      for (int i = 0; i < _jadwal!.data!.length; i++) {
        if (_jadwal!.data![i].hari.toLowerCase() == today.toLowerCase()) {
          targetIndex = i;
          break;
        }
      }
    }

    if (targetIndex == null || !_dayKeys.containsKey(targetIndex)) return;

    final context = _dayKeys[targetIndex]!.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    } else if (retry) {
      // Target not built yet — try again after the next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryScrollToToday());
    }
  }

  Future<void> _generatePdf() async {
    if (_jadwal?.data == null) return;

    final l10n = AppLocalizations.of(context)!;
    final pdf = pw.Document();
    final user = _sessionManager.getUser();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Professional Header
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 20),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(
                    color: PdfColor.fromInt(0xFF003D82),
                    width: 2,
                  ),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        l10n.pdfScheduleTitle,
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF003D82),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'SMART Mahasiswa UIN Salatiga',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        l10n.pdfPrintedAt,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      // Numeric date — locale-independent (only id_ID date
                      // symbols are initialized, and the default PDF font
                      // cannot shape non-Latin digits/month names).
                      pw.Text(
                        DateFormat('dd/MM/yyyy, HH:mm').format(DateTime.now()),
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Student Identity Info Card
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _pdfInfoRow(l10n.pdfName, user?.nama ?? '-'),
                        pw.SizedBox(height: 4),
                        _pdfInfoRow('NIM', user?.nim ?? '-'),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _pdfInfoRow(
                          l10n.semester,
                          _selectedSemester.toString(),
                        ),
                        pw.SizedBox(height: 4),
                        _pdfInfoRow(
                          l10n.pdfYear,
                          DateTime.now().year.toString(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 32),

            // Schedule Table
            ..._jadwal!.data!.map((day) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFF003D82),
                      borderRadius: pw.BorderRadius.vertical(
                        top: pw.Radius.circular(8),
                      ),
                    ),
                    child: pw.Text(
                      day.hari.toUpperCase(),
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  pw.Table(
                    border: pw.TableBorder.all(
                      color: PdfColors.grey300,
                      width: 0.5,
                    ),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(3),
                      1: const pw.FlexColumnWidth(1),
                      2: const pw.FlexColumnWidth(1.5),
                      3: const pw.FlexColumnWidth(2),
                    },
                    children: [
                      // Header Row
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey200,
                        ),
                        children: [
                          _pdfTableCell(l10n.pdfCourse, isHeader: true),
                          _pdfTableCell(l10n.credit, isHeader: true),
                          _pdfTableCell(l10n.pdfTimeRoom, isHeader: true),
                          _pdfTableCell(l10n.pdfLecturer, isHeader: true),
                        ],
                      ),
                      // Data Rows
                      ...day.itemMakul.map((mk) {
                        final isNotScheduled =
                            mk.waktu.toLowerCase().contains(
                              'tidak dijadwalkan',
                            ) ||
                            mk.waktu.trim().isEmpty ||
                            mk.waktu == '-';
                        return pw.TableRow(
                          children: [
                            _pdfTableCell(mk.makul),
                            _pdfTableCell(mk.sks.toString()),
                            _pdfTableCell(
                              isNotScheduled
                                  ? '-'
                                  : '${mk.waktu}\n(${mk.ruang})',
                            ),
                            _pdfTableCell(isNotScheduled ? '-' : mk.dosen),
                          ],
                        );
                      }),
                    ],
                  ),
                  pw.SizedBox(height: 24),
                ],
              );
            }),
          ];
        },
      ),
    );

    try {
      final output = await getApplicationDocumentsDirectory();
      final file = File(
        "${output.path}/Jadwal_Semester_$_selectedSemester.pdf",
      );

      final bytes = await pdf.save();
      await file.writeAsBytes(bytes, flush: true);

      final result = await OpenFilex.open(file.path);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      if (result.type != ResultType.done) {
        AppNotifications.show(
          context,
          '${l10n.cantOpenPdf}: ${result.message}',
          type: AppNotificationType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        AppNotifications.show(
          context,
          '${l10n.failedSavePdf}: $e',
          type: AppNotificationType.error,
        );
      }
    }
  }

  pw.Widget _pdfInfoRow(String label, String value) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 60,
          child: pw.Text(
            '$label:',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  pw.Widget _pdfTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  void _showSemesterPicker() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.only(top: 12, bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.semester,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _originalSemester,
                  itemBuilder: (context, index) {
                    final sem = index + 1;
                    final isSelected = sem == _selectedSemester;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        title: Text(
                          '${l10n.semester} $sem',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          if (sem != _selectedSemester) {
                            setState(() => _selectedSemester = sem);
                            _loadJadwal();
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.scheduleTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                AppNotifications.show(
                  context,
                  AppLocalizations.of(context)!.preparingPdf,
                  type: AppNotificationType.info,
                  duration: const Duration(seconds: 1),
                );
                _generatePdf();
              },
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.download_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showSemesterPicker,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${l10n.semester} $_selectedSemester',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
      // Swipe-to-refresh also retries a failed load (error/empty states are
      // scrollable so the gesture always works).
      body: RefreshIndicator(
        onRefresh: () => _loadJadwal(showFullLoading: false),
        color: AppColors.primary,
        child: switch (_state) {
          _ScheduleLoadState.loading => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.32),
              const Center(
                child: SpinKitThreeBounce(color: AppColors.primary, size: 30),
              ),
            ],
          ),
          _ScheduleLoadState.noData => _buildEmptyState(l10n),
          _ScheduleLoadState.serverMessage => _buildEmptyState(
            l10n,
            message: _errorMessage,
          ),
          _ScheduleLoadState.serverError => ErrorStateWidget(
            type: ErrorStateType.serverError,
            serverMessage: _errorMessage ?? l10n.errorResponseApi,
          ),
          _ScheduleLoadState.noInternet => const ErrorStateWidget(
            type: ErrorStateType.noInternet,
          ),
          _ScheduleLoadState.success => ListView.builder(
            controller: _scrollController,
            // Pre-build ALL day sections (a week is only ~5-7 sections) so
            // the auto-scroll target below the fold has a context — a lazy
            // list would otherwise never build it and the scroll would be
            // silently skipped.
            cacheExtent: MediaQuery.of(context).size.height * 3,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            itemCount: _jadwal!.data!.length,
            itemBuilder: (context, index) {
              final day = _jadwal!.data![index];
              // Stable key per index (never recreate — a new GlobalKey on
              // every rebuild would orphan the scroll target lookup).
              _dayKeys.putIfAbsent(index, GlobalKey.new);
              return _buildDaySection(index, day, l10n);
            },
          ),
        },
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, {String? message}) {
    return ListView(
      // Always scrollable so swipe-to-refresh keeps working here.
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.14),
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.03),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
              const Icon(
                Icons.calendar_month_outlined,
                size: 70,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            l10n.noSchedule,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            // Server message when the API answered with one, else the
            // default localized subtitle.
            message ?? l10n.noScheduleSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDaySection(int index, Hari day, AppLocalizations l10n) {
    final isToday =
        day.hari.toLowerCase() ==
            DateFormat('EEEE', 'id_ID').format(DateTime.now()).toLowerCase() &&
        _selectedSemester == _originalSemester;

    return Column(
      key: _dayKeys[index],
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: isToday
                    ? const LinearGradient(
                        colors: [Color(0xFFFB8C00), Color(0xFFFFA726)],
                      )
                    : mainGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: (isToday ? AppColors.secondary : AppColors.primary)
                        .withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                day.hari.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            if (isToday) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.today.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        ...day.itemMakul.map((mk) => _buildScheduleCard(mk, l10n)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildScheduleCard(MataKuliah mk, AppLocalizations l10n) {
    final isNotScheduled =
        mk.waktu.toLowerCase().contains('tidak dijadwalkan') ||
        mk.waktu.trim().isEmpty ||
        mk.waktu == '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: mainGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
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
                          mk.makul,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_rounded,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                mk.dosen,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '${mk.sks} ${l10n.credit}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (!isNotScheduled) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildInfoChip(Icons.access_time_rounded, mk.waktu),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      Icons.location_on_outlined,
                      '${l10n.room} ${mk.ruang}',
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: AppColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
