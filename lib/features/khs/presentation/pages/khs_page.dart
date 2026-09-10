import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/session_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_notifications.dart';
import '../../../../core/utils/subscription_gate.dart';
import '../../../../core/widgets/action_required_dialog.dart';
import '../../../bills/presentation/widgets/error_state_widget.dart';
import '../../../edom/presentation/pages/edom_semesters_page.dart';
import '../../data/models/khs_response.dart';

/// Mirrors the legacy `KhsActivity` business logic:
/// - loads the CURRENT semester KHS on init (Future.microtask so context
///   is ready); semester options are 1..user.semester (legacy PopupMenu)
/// - summary card: semester + total SKS (legacy count_sks) + IPS
///   (legacy count_ip: Σ(sks × nilaiangka) / Σsks, "%.2f")
/// - one card per graded course: SKS badge, makul name, bobot nilai
///   (nilaiangka), kelas, and the letter-grade (nilaihuruf) badge
/// - `cekeval == false` -> blocking dialog directing the student to fill
///   EDOM first (general action-required dialog), replacing this page
/// - failure states exactly like legacy show_data(): server message /
///   no-internet / no data
/// - app bar download button exports the loaded KHS to PDF
///   (legacy ExportRecyclertoPDF "KHS Semester {n}")
enum _KhsLoadState { loading, success, noData, serverError, noInternet }

class KhsPage extends StatefulWidget {
  const KhsPage({super.key});

  @override
  State<KhsPage> createState() => _KhsPageState();
}

class _KhsPageState extends State<KhsPage> {
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF003D82), Color(0xFF0056B3)],
  );

  final _apiService = ApiService();
  final _sessionManager = SessionManager();

  KhsResponse? _khs;
  _KhsLoadState _state = _KhsLoadState.loading;

  /// Legacy: `semester_sekarang` (user.semester, default 8) and
  /// `selected_semester` initialized to it.
  int _currentSemester = 8;
  int _selectedSemester = 0;

  @override
  void initState() {
    super.initState();
    final user = _sessionManager.getUser();
    if (user != null && user.semester != null) {
      _currentSemester = user.semester!;
    }
    _selectedSemester = _currentSemester;
    Future.microtask(() {
      if (!mounted) return;
      checkSubscription(context, SubscriptionGateFeatures.khs);
      _loadKhs();
    });
  }

  Future<void> _loadKhs() async {
    if (!mounted) return;
    setState(() => _state = _KhsLoadState.loading);

    final user = _sessionManager.getUser();
    if (user == null) {
      if (mounted) setState(() => _state = _KhsLoadState.noInternet);
      return;
    }

    final result = await _apiService.getKhs(
      semester: _selectedSemester,
      nim: user.nim ?? '',
      kdjen: user.kodeJen ?? '',
      kdpst: user.kodePst ?? '',
    );

    if (!mounted) return;

    // Legacy EDOM gate: student must complete the lecturer evaluation
    // before the KHS may be seen. Blocking dialog -> go fill EDOM
    // (replaces this page, legacy finishes the activity).
    if (!result.cekEval) {
      setState(() => _state = _KhsLoadState.noData);
      final l10n = AppLocalizations.of(context)!;
      await showActionRequiredDialog(
        context: context,
        message: l10n.evalRequiredMessage,
        actionLabel: l10n.completeLecturerEval,
        onAction: () {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const EdomSemestersPage()),
          );
        },
      );
      return;
    }

    setState(() {
      _khs = result;
      if (result.success && result.data != null) {
        _state = _KhsLoadState.success;
      }else if(!result.success){
        _state = _KhsLoadState.noData;
      } else if (result.message != null && result.message!.isNotEmpty) {
        _state = _KhsLoadState.serverError;
      } else {
        _state = _KhsLoadState.noInternet;
      }
    });
  }

  /// Legacy `PerhitunganAkademik().count_sks` — sum of course SKS.
  int get _totalSks {
    return (_khs?.data ?? const <KhsData>[]).fold(0, (a, e) => a + e.sks);
  }

  /// Legacy `PerhitunganAkademik().count_ip` —
  /// Σ(sks × nilaiangka) / Σsks formatted "%.2f" (comma forced to dot).
  String get _ips {
    final items = _khs?.data ?? const <KhsData>[];
    var sks = 0;
    var nilaiMutu = 0.0;
    for (final e in items) {
      sks += e.sks;
      nilaiMutu += e.sks * e.nilaiangka;
    }
    if (sks == 0) return '0.00';
    return _twoDecimals.format(nilaiMutu / sks);
  }

  /// Dot separator, exactly like the legacy `.replace(',', '.')`.
  static final NumberFormat _twoDecimals = NumberFormat('0.00', 'en_US');

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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.khsTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: mainGradient),
        ),
        actions: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (_state != _KhsLoadState.success) {
                  // Legacy toast: "Tunggu sampai KHS selesai dimuat".
                  AppNotifications.show(
                    context,
                    l10n.khsWaitUntilLoaded,
                    type: AppNotificationType.info,
                  );
                  return;
                }
                AppNotifications.show(
                  context,
                  l10n.preparingPdf,
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
      // scrollable so the gesture always works) — legacy SwipeRefreshLayout.
      body: RefreshIndicator(
        onRefresh: _loadKhs,
        color: AppColors.primary,
        child: switch (_state) {
          _KhsLoadState.loading => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.32),
              const Center(
                child: SpinKitThreeBounce(color: AppColors.primary, size: 30),
              ),
            ],
          ),
          _KhsLoadState.noData => ErrorStateWidget(
            // Same style as the bills pages (tagihan): big translucent
            // icon + message, scrollable so swipe-to-refresh keeps working.
            type: ErrorStateType.noData,
            noDataMessage:_khs!.message,
            noDataIcon: Icons.receipt_long_rounded,
          ),
          _KhsLoadState.serverError => ErrorStateWidget(
            type: ErrorStateType.serverError,
            serverMessage: _khs?.message,
          ),
          _KhsLoadState.noInternet => const ErrorStateWidget(
            type: ErrorStateType.noInternet,
          ),
          _KhsLoadState.success => ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            itemCount: (_khs?.data?.length ?? 0) + 1, // index 0 = summary
            itemBuilder: (context, index) {
              if (index == 0) return _buildSummaryCard(l10n);
              final item = _khs!.data![index - 1];
              return _buildMakulCard(item, l10n);
            },
          ),
        },
      ),
    );
  }

  /// Kartu ringkasan: semester, SKS semester dan IPS
  /// (setara activity_khs.xml: textsem / textsks / textip).
  ///
  /// Relayout: 3 kolom statistik yang sama lebar dengan pembatas —
  /// label boleh wrap (tanpa ellipsis) dan nilai di dalam FittedBox
  /// sehingga SEMUA data selalu tampil penuh.
  Widget _buildSummaryCard(AppLocalizations l10n) {
    final semester = (_khs?.semester != null && _khs!.semester!.isNotEmpty)
        ? _khs!.semester!
        : _selectedSemester.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: mainGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header kartu
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.khsTitle,
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Statistik: Semester | SKS Semester | IPS
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildStatItem(label: l10n.semester, value: semester),
                ),
                _buildStatDivider(),
                Expanded(
                  child: _buildStatItem(
                    label: l10n.khsSemesterSks,
                    value: _totalSks.toString(),
                  ),
                ),
                _buildStatDivider(),
                Expanded(
                  child: _buildStatItem(
                    label: l10n.ips,
                    value: _ips,
                    highlight: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Satu statistik pada kartu ringkasan — label wrap penuh (bebas
  /// ellipsis) dan nilai dalam FittedBox (menyusut, tidak pernah terpotong).
  Widget _buildStatItem({
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          softWrap: true,
          style: TextStyle(
            fontSize: 11.5,
            height: 1.25,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              fontSize: highlight ? 28 : 24,
              fontWeight: FontWeight.bold,
              // Legacy textip memakai warna oranye pada angka IPS.
              color: highlight ? AppColors.secondary : Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  /// Pembatas tipis antar statistik pada kartu ringkasan.
  Widget _buildStatDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      width: 1,
      color: Colors.white.withValues(alpha: 0.25),
    );
  }

  /// Kartu mata kuliah: badge SKS, nama, bobot nilai, kelas, index nilai
  /// (setara view_khs.xml).
  Widget _buildMakulCard(KhsData item, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    '${item.sks} ${l10n.credit}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.nilaihuruf,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.makul,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.bar_chart_rounded,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${l10n.khsGradeWeight}: ${_formatAngka(item.nilaiangka)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.meeting_room_rounded,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${l10n.classLabel}: ${item.kelas}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Legacy shows `nilaiangka.toString()` — avoid trailing ".0" noise in
  /// Dart by keeping at most 2 decimals (dot separator).
  String _formatAngka(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return _twoDecimals.format(value);
  }

  /// Filter semester — 1..semester_sekarang (legacy PopupMenu).
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
                  itemCount: _currentSemester,
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
                            _loadKhs();
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

  /// Export KHS to PDF (legacy menu_download_pdf ->
  /// ExportRecyclertoPDF "KHS Semester {n}").
  Future<void> _generatePdf() async {
    if (_khs?.data == null) return;

    final l10n = AppLocalizations.of(context)!;
    final user = _sessionManager.getUser();
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
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
                        l10n.khsPdfTitle,
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
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
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
                          '${_khs?.semester ?? _selectedSemester}',
                        ),
                        pw.SizedBox(height: 4),
                        _pdfInfoRow(
                          '${l10n.khsSemesterSks} / ${l10n.ips}',
                          '$_totalSks / $_ips',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3.5),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _pdfTableCell(l10n.pdfCourse, isHeader: true),
                    _pdfTableCell(l10n.credit, isHeader: true),
                    _pdfTableCell(l10n.classLabel, isHeader: true),
                    _pdfTableCell(l10n.khsGradeWeight, isHeader: true),
                    _pdfTableCell(l10n.khsGradeIndex, isHeader: true),
                  ],
                ),
                ..._khs!.data!.map(
                  (mk) => pw.TableRow(
                    children: [
                      _pdfTableCell(mk.makul),
                      _pdfTableCell(mk.sks.toString()),
                      _pdfTableCell(mk.kelas),
                      _pdfTableCell(_formatAngka(mk.nilaiangka)),
                      _pdfTableCell(mk.nilaihuruf),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    try {
      final output = await getApplicationDocumentsDirectory();
      final file = File('${output.path}/KHS_Semester_$_selectedSemester.pdf');

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
}
