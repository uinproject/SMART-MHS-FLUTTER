import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/session_manager.dart';
import '../../../home/data/models/jadwal_response.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final _apiService = ApiService();
  final _sessionManager = SessionManager();
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _dayKeys = {};

  JadwalResponse? _jadwal;
  bool _isLoading = true;
  int _selectedSemester = 0;
  int _originalSemester = 0;

  @override
  void initState() {
    super.initState();
    final user = _sessionManager.getUser();
    if (user != null) {
      _selectedSemester = user.semester ?? 1;
      _originalSemester = _selectedSemester;
      // Use microtask to ensure context is ready for Localization if needed
      Future.microtask(() => _loadJadwal());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadJadwal() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final user = _sessionManager.getUser();
      if (user != null) {
        final result = await _apiService.getJadwalmhs(
          nim: user.nim ?? '',
          semester: _selectedSemester,
          language: Localizations.localeOf(context).languageCode,
        );
        if (mounted) {
          setState(() {
            _jadwal = result;
            _isLoading = false;
          });
          
          if (_selectedSemester == _originalSemester) {
            _scrollToToday();
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToToday() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

      if (targetIndex != null && _dayKeys.containsKey(targetIndex)) {
        final context = _dayKeys[targetIndex]!.currentContext;
        if (context != null) {
          // ensureVisible with margin
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            alignment: 0.1, // This helps to keep some space at the top
          );
        }
      }
    });
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();
    final user = _sessionManager.getUser();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('JADWAL KULIAH', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Text('NIM: ${user?.nim ?? "-"}'),
                  pw.Text('Nama: ${user?.nama ?? "-"}'),
                  pw.Text('Semester: $_selectedSemester'),
                  pw.Divider(),
                ],
              ),
            ),
            if (_jadwal?.data != null)
              ..._jadwal!.data!.map((day) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 10),
                      child: pw.Text(day.hari.toUpperCase(), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    ),
                    ...day.itemMakul.map((mk) {
                      return pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 5),
                        padding: const pw.EdgeInsets.all(5),
                        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(mk.makul, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            pw.Text('Waktu: ${mk.waktu}'),
                            pw.Text('Ruang: ${mk.ruang}'),
                            pw.Text('Dosen: ${mk.dosen}'),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              }),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        title: Text(
                          '${l10n.semester} $sem', 
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
    const mainGradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [Color(0xFF003D82), Color(0xFF0056B3)],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            toolbarHeight: 70,
            backgroundColor: const Color(0xFF003D82),
            elevation: 0,
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              l10n.scheduleTitle,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Menyiapkan dokumen PDF...'), duration: Duration(seconds: 1)),
                    );
                    _generatePdf();
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Sem $_selectedSemester',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
            ],
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: SpinKitThreeBounce(color: AppColors.primary, size: 30)),
            )
          else if (_jadwal?.data == null || _jadwal!.data!.isEmpty)
            SliverFillRemaining(
              child: Center(child: Text(l10n.noSchedule)),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final day = _jadwal!.data![index];
                    _dayKeys[index] = GlobalKey();
                    return _buildDaySection(index, day, l10n);
                  },
                  childCount: _jadwal!.data!.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDaySection(int index, Hari day, AppLocalizations l10n) {
    final isToday = day.hari.toLowerCase() == DateFormat('EEEE', 'id_ID').format(DateTime.now()).toLowerCase() && _selectedSemester == _originalSemester;

    return Column(
      key: _dayKeys[index],
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isToday ? AppColors.secondary : AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                day.hari.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
            if (isToday) ...[
              const SizedBox(width: 8),
              Text(
                l10n.today.toUpperCase(),
                style: const TextStyle(color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.w900),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
                child: Text(
                  mk.makul,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${mk.sks} ${l10n.credit}',
                  style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.access_time_rounded, mk.waktu),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.location_on_outlined, '${l10n.room} ${mk.ruang}'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.person_outline_rounded, mk.dosen),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
