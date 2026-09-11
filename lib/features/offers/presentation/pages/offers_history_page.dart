import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/session_manager.dart';
import '../../data/models/penawaran_response.dart';
import '../../../bills/presentation/widgets/error_state_widget.dart';

/// Mirrors the legacy `RiwayatInputPenawaranMKActivity` business logic:
/// - semester filter built as 1..current semester (default = current)
/// - loads riwayat on init & on filter change (Future.microtask so context
///   is ready)
/// - state handling: success / server message / no internet (tri-state)
/// - groups per semester as "Paket Semester N" (legacy green header)
/// - pull-to-refresh (legacy SwipeRefreshLayout)
enum _RiwayatLoadState { loading, success, noData, serverError, noInternet }

class OffersHistoryPage extends StatefulWidget {
  const OffersHistoryPage({super.key});

  @override
  State<OffersHistoryPage> createState() => _OffersHistoryPageState();
}

class _OffersHistoryPageState extends State<OffersHistoryPage> {
  final _apiService = ApiService();
  final _sessionManager = SessionManager();

  PenawaranRiwayatResponse? _riwayat;
  _RiwayatLoadState _state = _RiwayatLoadState.loading;
  int _selectedSemester = 0;
  int _currentSemester = 1;

  @override
  void initState() {
    super.initState();
    final user = _sessionManager.getUser();
    _currentSemester = user?.semester ?? 1;
    _selectedSemester = _currentSemester;
    Future.microtask(() => _loadRiwayat());
  }

  Future<void> _loadRiwayat() async {
    if (!mounted) return;
    setState(() => _state = _RiwayatLoadState.loading);

    final user = _sessionManager.getUser();
    if (user == null) {
      if (mounted) setState(() => _state = _RiwayatLoadState.noInternet);
      return;
    }

    final result = await _apiService.getPenawaranRiwayat(
      nim: user.nim ?? '',
      kdjen: user.kodeJen ?? '',
      kdpst: user.kodePst ?? '',
      semester: _selectedSemester,
    );

    if (!mounted) return;
    setState(() {
      _riwayat = result;
      if (result.success && result.data != null && result.data!.isNotEmpty) {
        _state = _RiwayatLoadState.success;
      } else if (result.success) {
        _state = _RiwayatLoadState.noData;
      } else if (result.message != null) {
        _state = _RiwayatLoadState.serverError;
      } else {
        _state = _RiwayatLoadState.noInternet;
      }
    });
  }

  /// Semester picker styled exactly like the one in schedule_page.dart
  /// (legacy used a PopupMenu with items 1..user.semester).
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
                  itemCount: _currentSemester,
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
                            _loadRiwayat();
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.offerHistoryTitle,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        // Semester filter (legacy PopupMenu), styled like schedule_page.
        actions: [
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
      body: RefreshIndicator(
        onRefresh: _loadRiwayat,
        color: AppColors.primary,
        child: switch (_state) {
          _RiwayatLoadState.loading => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 300),
                Center(child: SpinKitThreeBounce(color: AppColors.primary, size: 30)),
              ],
            ),
          _RiwayatLoadState.noData => ErrorStateWidget(
              type: ErrorStateType.noData,
              noDataMessage: l10n.noOfferHistory,
              noDataIcon: Icons.history_rounded,
            ),
          _RiwayatLoadState.serverError => ErrorStateWidget(
              type: ErrorStateType.serverError,
              serverMessage: _riwayat?.message,
            ),
          _RiwayatLoadState.noInternet => const ErrorStateWidget(type: ErrorStateType.noInternet),
          _RiwayatLoadState.success => ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _riwayat!.data!.length,
              itemBuilder: (context, index) {
                final semester = _riwayat!.data![index];
                return _buildSemesterCard(semester, l10n);
              },
            ),
        },
      ),
    );
  }

  /// One white card per semester package (legacy: green group header +
  /// rows separated by dividers).
  Widget _buildSemesterCard(PenawaranRiwayatSemester semester, AppLocalizations l10n) {
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
        children: [
          // Green "Paket Semester N" header (legacy color kept).
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Text(
              '${l10n.semesterPackage} ${semester.semester}',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
            ),
          ),
          ...semester.itemMakul.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Column(
              children: [
                if (i > 0)
                  Divider(height: 1, color: AppColors.iconBackground.withValues(alpha: 0.6)),
                _buildRiwayatRow(item, l10n),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRiwayatRow(PenawaranRiwayatMataKuliah item, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.namaMk,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '${item.sksMk} SKS',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.khsYear(item.thsmsMk.toString()),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              const Spacer(),
              if (item.tglInputPmk != null && item.tglInputPmk!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    item.tglInputPmk!,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
