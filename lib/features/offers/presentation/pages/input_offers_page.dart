import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/session_manager.dart';
import '../../../../core/utils/app_notifications.dart';
import '../../../../core/widgets/action_required_dialog.dart';
import '../../data/models/penawaran_response.dart';
import '../../../bills/presentation/widgets/error_state_widget.dart';
import '../../../edom/presentation/pages/edom_semesters_page.dart';

/// Mirrors the legacy `InputPenawaranMkActivity` business logic:
/// - loads the offering list on init (Future.microtask so context is ready)
/// - info card: SKS quota (default 12) + input start/end dates
/// - `cekeval == false` -> blocking "complete lecturer evaluation" dialog
/// - selection rules (same as legacy adapters):
///   * `keterangan == "ms"` -> selectable, else row disabled + `desc` shown
///   * `sudah_input_pmk == "Y"` -> auto-checked within quota on load
///   * checking beyond the SKS quota -> red error snackbar
/// - save button enabled only when something is selected
/// - submit -> hashed JSON array `[{"kode_mk":..,"sks_mk":..}]`
/// - after success: selected -> Y + tgl_input, stale Y entries reset to T
/// - pull-to-refresh clears the selection first (legacy static-reset)
enum _OffersLoadState { loading, success, noData, serverError, noInternet }

class InputOffersPage extends StatefulWidget {
  const InputOffersPage({super.key});

  @override
  State<InputOffersPage> createState() => _InputOffersPageState();
}

class _InputOffersPageState extends State<InputOffersPage> {
  final _apiService = ApiService();
  final _sessionManager = SessionManager();

  PenawaranListResponse? _offers;
  _OffersLoadState _state = _OffersLoadState.loading;

  /// kode_mk -> sks_mk (mirrors the legacy static selection set of
  /// PenawaranMKformatdata elements).
  final Map<String, int> _selected = {};

  /// Legacy default when the server omits `jatah_sks`.
  int get _jatahSks => _offers?.jatahSks ?? 12;

  int get _selectedTotalSks => _selected.values.fold(0, (a, b) => a + b);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadOffers());
  }

  Future<void> _loadOffers() async {
    if (!mounted) return;
    setState(() {
      _state = _OffersLoadState.loading;
      _selected.clear(); // legacy pull-to-refresh resets the static selection
    });

    final user = _sessionManager.getUser();
    if (user == null) {
      if (mounted) setState(() => _state = _OffersLoadState.noInternet);
      return;
    }

    // NIM is hashed AS-IS here (legacy PMK does not digits-filter the NIM).
    final result = await _apiService.getPenawaranList(
      nim: user.nim ?? '',
      kdjen: user.kodeJen ?? '',
      kdpst: user.kodePst ?? '',

    );

    if (!mounted) return;
    setState(() {
      _offers = result;
      if (result.success && result.data != null && result.data!.isNotEmpty) {
        _state = _OffersLoadState.success;
      } else if (result.success) {
        _state = _OffersLoadState.noData;
      } else if (result.message != null) {
        _state = _OffersLoadState.serverError;
      } else {
        _state = _OffersLoadState.noInternet;
      }
    });

    final bool overQuota = _state == _OffersLoadState.success
        ? _reconcileAutoChecked()
        : false;

    // Legacy: student must complete Edom before inputting offers — the
    // dialog shows whenever the API answered with cekeval == false,
    // regardless of the list state (legacy checks `!cekeval` right after
    // the 200 response, after show_data()).
    if (result.cekEval == false) {
      _showEvalRequiredDialog();
    } else if (overQuota) {
      _showOverQuotaSnackbar();
    }
  }

  /// Auto-checks every `sudah_input_pmk == "Y"` course that still fits the
  /// quota (legacy does this on adapter bind). Returns true when at least
  /// one Y course had to be left unchecked because of the quota.
  bool _reconcileAutoChecked() {
    _selected.clear();
    bool overQuota = false;
    int total = 0;
    for (final sem in _offers?.data ?? const <PenawaranSemester>[]) {
      for (final mk in sem.itemMakul) {
        if (mk.selectable && mk.sudahInputPmk == 'Y') {
          if (total + mk.sksMk <= _jatahSks) {
            _selected[mk.kdmkMk] = mk.sksMk;
            total += mk.sksMk;
          } else {
            overQuota = true;
          }
        }
      }
    }
    setState(() {}); // refresh checkbox states
    return overQuota;
  }

  void _toggleCourse(PenawaranMataKuliah mk) {
    if (!mk.selectable) return;
    if (_selected.containsKey(mk.kdmkMk)) {
      setState(() => _selected.remove(mk.kdmkMk));
    } else if (_selectedTotalSks + mk.sksMk <= _jatahSks) {
      setState(() => _selected[mk.kdmkMk] = mk.sksMk);
    } else {
      _showOverQuotaSnackbar();
    }
  }

  void _showOverQuotaSnackbar() {
    final l10n = AppLocalizations.of(context)!;
    AppNotifications.show(
      context,
      l10n.sksLimitExceeded(_jatahSks),
      type: AppNotificationType.error,
    );
  }

  /// Blocking dialog (legacy: Lottie star + `text_show_dialog_eval`).
  /// Uses the general action-required dialog; the action replaces this
  /// page with the EDOM flow (legacy: startActivity + finish()).
  void _showEvalRequiredDialog() {
    final l10n = AppLocalizations.of(context)!;
    showActionRequiredDialog(
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
  }

  void _showSubmitLoadingDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SpinKitThreeBounce(color: AppColors.primary, size: 30),
                const SizedBox(height: 16),
                Text(
                  l10n.pleaseWait,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showResultDialog({
    required bool success,
    required String message,
    VoidCallback? onOk,
  }) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: (success ? AppColors.success : AppColors.danger)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  success ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: success ? AppColors.success : AppColors.danger,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    onOk?.call();
                  },
                  child: Text(l10n.okButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitSelection() async {
    final user = _sessionManager.getUser();
    if (user == null || _selected.isEmpty) return;

    // Same payload shape as legacy Gson().toJson(set):
    // [{"kode_mk":"...","sks_mk":2}, ...]
    final payload = jsonEncode([
      for (final e in _selected.entries) {'kode_mk': e.key, 'sks_mk': e.value},
    ]);

    _showSubmitLoadingDialog();

    final result = await _apiService.submitPenawaran(
      nim: user.nim ?? '',
      kdjen: user.kodeJen ?? '',
      kdpst: user.kodePst ?? '',
      dataJson: payload,
    );

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // close loading dialog

    _showResultDialog(
      success: result.success,
      message: result.message,
      onOk: result.success ? () => _applyPostSubmit(result.tglInput) : null,
    );
  }

  /// Mirrors legacy `update_tgl_input()`: selected courses become Y with the
  /// new input date; previously-input-but-unselected courses are reset to T
  /// (the new submission replaced the old one). The selection is then cleared
  /// and Y-courses are auto-rechecked within the quota (legacy re-bind).
  void _applyPostSubmit(String tglInput) {
    final tgl = tglInput.isEmpty ? 'xxx' : tglInput; // legacy fallback
    setState(() {
      for (final sem in _offers?.data ?? const <PenawaranSemester>[]) {
        for (final mk in sem.itemMakul) {
          if (_selected.containsKey(mk.kdmkMk)) {
            mk.sudahInputPmk = 'Y';
            mk.tglInputPmk = tgl;
          } else if (mk.sudahInputPmk == 'Y' && mk.tglInputPmk != tgl) {
            mk.sudahInputPmk = 'T';
            mk.tglInputPmk = null;
          }
        }
      }
      _selected.clear();
    });
    _reconcileAutoChecked();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final bool hasOffers = _state == _OffersLoadState.success;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.inputOfferTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadOffers,
        color: AppColors.primary,
        child: switch (_state) {
          _OffersLoadState.loading => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 300),
              Center(
                child: SpinKitThreeBounce(color: AppColors.primary, size: 30),
              ),
            ],
          ),
          _OffersLoadState.noData => ErrorStateWidget(
            type: ErrorStateType.noData,
            noDataMessage: l10n.noOfferings,
            noDataIcon: Icons.local_offer_rounded,
          ),
          _OffersLoadState.serverError => ErrorStateWidget(
            type: ErrorStateType.serverError,
            serverMessage: _offers?.message,
          ),
          _OffersLoadState.noInternet => const ErrorStateWidget(
            type: ErrorStateType.noInternet,
          ),
          _OffersLoadState.success => ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
            itemCount: _offers!.data!.length + 1, // index 0 = info card
            itemBuilder: (context, index) {
              if (index == 0) return _buildInfoCard(l10n);
              final semester = _offers!.data![index - 1];
              return _buildSemesterGroup(semester, l10n);
            },
          ),
        },
      ),
      // Bottom summary + "Simpan" only when the offering list is loaded
      // (legacy disables/hides the save action otherwise).
      bottomNavigationBar: hasOffers
          ? Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.selectedCoursesCount(
                                _selected.length,
                                _selectedTotalSks,
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '$_selectedTotalSks/$_jatahSks SKS',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _selected.isNotEmpty
                            ? _submitSelection
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.primary.withValues(
                            alpha: 0.35,
                          ),
                          disabledForegroundColor: Colors.white,
                          // Override theme default minimumSize (double.infinity, 56):
                          // infinite min width breaks layout inside a Row.
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          l10n.save,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
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
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.information,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '${l10n.sksQuota}: $_jatahSks SKS',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(l10n.offerStartLabel, _offers?.waktuMulai),
          const SizedBox(height: 8),
          _buildInfoRow(l10n.offerEndLabel, _offers?.waktuSelesai),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value == null || value.isEmpty ? '-' : value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSemesterGroup(
    PenawaranSemester semester,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            '${l10n.semester} ${semester.semester}'.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.primary,
              letterSpacing: 1,
            ),
          ),
        ),
        ...semester.itemMakul.map((item) => _buildCourseCard(item)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCourseCard(PenawaranMataKuliah item) {
    final bool checked = _selected.containsKey(item.kdmkMk);
    final bool enabled = item.selectable;

    final content = Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Checkbox(
            value: checked,
            onChanged: enabled ? (_) => _toggleCourse(item) : null,
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '(${item.kdmkMk}) ${item.namaMk}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        '${item.sksMk} SKS',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    if (item.tglInputPmk != null &&
                        item.tglInputPmk!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.tglInputPmk!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (item.pernahAmbilMk.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.pernahAmbilMk,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (!enabled && item.descPlain.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.descPlain,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      // "tms" rows are disabled entirely (checkbox + row), same as legacy.
      child: enabled
          ? Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: () => _toggleCourse(item),
                borderRadius: BorderRadius.circular(24),
                child: content,
              ),
            )
          : Opacity(opacity: 0.55, child: IgnorePointer(child: content)),
    );
  }
}
