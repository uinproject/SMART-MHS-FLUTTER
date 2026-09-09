import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/session_manager.dart';
import '../../data/models/krs_response.dart';
import '../../../bills/presentation/widgets/error_state_widget.dart';

/// Mirrors the legacy `KrsMKActivity` business logic:
/// - loads the current-semester KRS on init (Future.microtask so context
///   is ready), pull-to-refresh reloads it
/// - info card: running semester (server value, fallback user.semester)
///   + approved SKS total (sum of `sks` parsed as int, legacy count_sks)
/// - one card per taken course: header (makul) + 2-column detail grid
///   (kode MK, paket semester, SKS, kelas, dosen, "waktu (ruang)")
/// - failure states exactly like legacy showdata(): server message vs
///   no-internet
enum _KrsLoadState { loading, success, serverError, noInternet }

class ViewKrsPage extends StatefulWidget {
  const ViewKrsPage({super.key});

  @override
  State<ViewKrsPage> createState() => _ViewKrsPageState();
}

class _ViewKrsPageState extends State<ViewKrsPage> {
  final _apiService = ApiService();
  final _sessionManager = SessionManager();

  KrsResponse? _krs;
  _KrsLoadState _state = _KrsLoadState.loading;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadKrs());
  }

  Future<void> _loadKrs() async {
    if (!mounted) return;
    final language = Localizations.localeOf(context).languageCode;
    setState(() => _state = _KrsLoadState.loading);

    final user = _sessionManager.getUser();
    if (user == null) {
      if (mounted) setState(() => _state = _KrsLoadState.noInternet);
      return;
    }

    // NIM is hashed AS-IS (legacy KRS does not digits-filter the NIM).
    // NOTE: this endpoint uses the SHORT param names kdpst/kdjen.
    final result = await _apiService.getKrs(
      nim: user.nim ?? '',
      kdjen: user.kodeJen ?? '',
      kdpst: user.kodePst ?? '',
      language: language,
    );

    if (!mounted) return;
    setState(() {
      _krs = result;
      if (result.success && result.data != null) {
        _state = _KrsLoadState.success;
      } else if (result.message != null) {
        _state = _KrsLoadState.serverError;
      } else {
        _state = _KrsLoadState.noInternet;
      }
    });
  }

  /// Legacy: `semester_berjalan ?: user.semester.toString()`.
  String get _semesterLabel {
    final running = _krs?.semesterBerjalan;
    if (running != null && running.isNotEmpty) return running;
    return (_sessionManager.getUser()?.semester ?? 0).toString();
  }

  /// Legacy `PerhitunganAkademik().count_sks`: sum of `sks.toInt()` per item.
  int get _totalSks {
    return (_krs?.data ?? const <KrsItemMakul>[])
        .fold(0, (a, e) => a + (int.tryParse(e.sks) ?? 0));
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
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: const Color(0xFF003D82),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.viewKrsTitle,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: mainGradient),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadKrs,
        color: AppColors.primary,
        child: switch (_state) {
          _KrsLoadState.loading => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 300),
                Center(child: SpinKitThreeBounce(color: AppColors.primary, size: 30)),
              ],
            ),
          _KrsLoadState.serverError => ErrorStateWidget(
              type: ErrorStateType.serverError,
              serverMessage: _krs?.message,
            ),
          _KrsLoadState.noInternet => const ErrorStateWidget(type: ErrorStateType.noInternet),
          _KrsLoadState.success => ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              itemCount: (_krs?.data?.length ?? 0) + 1, // index 0 = info card
              itemBuilder: (context, index) {
                if (index == 0) return _buildInfoCard(l10n);
                final item = _krs!.data![index - 1];
                return _buildMakulCard(item, l10n);
              },
            ),
        },
      ),
    );
  }

  Widget _buildInfoCard(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                l10n.information,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(l10n.krsSemesterLabel, _semesterLabel),
          const SizedBox(height: 8),
          _buildInfoRow(l10n.approvedSksLabel, '$_totalSks ${l10n.credit}'),
          const Divider(height: 24, color: AppColors.iconBackground),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.secondary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.krsNote,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildMakulCard(KrsItemMakul item, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Header biru (setara view_krs_mhs.xml)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Text(
              item.makul,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildDetail(l10n.courseCode, item.kodeMk)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDetail(l10n.semesterPackage, item.paketSemester.toString())),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDetail(l10n.credit, item.sks)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDetail(l10n.classLabel, item.kelas)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildDetail(l10n.lecturer, item.dosen)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDetail(l10n.schedule, '${item.waktu} (${item.ruang})')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? '-' : value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
