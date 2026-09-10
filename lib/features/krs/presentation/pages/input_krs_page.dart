import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/session_manager.dart';
import '../../../../core/utils/subscription_gate.dart';
import '../../../../core/utils/app_notifications.dart';
import '../../../../core/widgets/action_required_dialog.dart';
import '../../../edom/presentation/pages/edom_semesters_page.dart';
import '../../data/models/krs_list_response.dart';
import '../../data/models/krs_input_item.dart';
import '../../data/krs_conflict_checker.dart';
import '../../../bills/presentation/widgets/error_state_widget.dart';

/// Mirrors the legacy `InputKrsMKActivity` + adapters business logic:
/// - loads the schedulable course list on init (Future.microtask), with the
///   subscription dialog check (krs@115) once per visit (dialog only)
/// - info card: input start/end dates + "approved KRS cannot be changed" note
/// - ONE schedule per course (radio behaviour inside a course); rows are
///   disabled when full (and not the student's saved row) or already approved
/// - auto-check on load: schedule with selected=="Y" becomes the course pick
/// - SCHEDULE-CONFLICT REJECTION (port 1:1 of the legacy check): tapping a
///   row that overlaps another course's picked schedule shows a red top
///   snackbar and the pick is REJECTED
/// - bottom bar: "n Mata Kuliah (s SKS)" + Simpan (enabled when the payload
///   is non-empty); submit posts the hashed JSON array (excluding isacc=="Y"
///   rows) and re-binds the fresh list from the response
enum _KrsMkLoadState { loading, success, noData, serverError, noInternet }

class InputKrsPage extends StatefulWidget {
  const InputKrsPage({super.key});

  @override
  State<InputKrsPage> createState() => _InputKrsPageState();
}

class _InputKrsPageState extends State<InputKrsPage> {
  final _apiService = ApiService();
  final _sessionManager = SessionManager();

  KrsListResponse? _list;
  _KrsMkLoadState _state = _KrsMkLoadState.loading;

  /// key = course (parent) index, value = picked schedule (child) index —
  /// replaces the legacy static `pilihan_jadwal` / `value_kdkmk` lists.
  final Map<int, int> _selected = {};

  List<KrsMataKuliah> get _makul => _list?.data ?? [];

  @override
  void initState() {
    super.initState();
    // Legacy: SubscriptionUtils.checkSubscription(krs@115) — dialog only,
    // never blocks the feature.
    Future.microtask(() {
      if (!mounted) return;
      checkSubscription(context, SubscriptionGateFeatures.krs);
      _loadKrsMk();
    });
  }

  Future<void> _loadKrsMk() async {
    if (!mounted) return;
    setState(() {
      _state = _KrsMkLoadState.loading;
      _selected.clear(); // legacy resets the static selection on load/refresh
    });

    final user = _sessionManager.getUser();
    if (user == null) {
      if (mounted) setState(() => _state = _KrsMkLoadState.noInternet);
      return;
    }

    // NOTE: this endpoint uses the LONG param names kode_pst/kode_jen.
    final result = await _apiService.getKrsList(
      nim: user.nim ?? '',
      kdjen: user.kodeJen ?? '',
      kdpst: user.kodePst ?? '',

    );

    if (!mounted) return;
    setState(() {
      _list = result;
      if (result.success && result.data != null) {
        _state = result.data!.isEmpty
            ? _KrsMkLoadState.noData
            : _KrsMkLoadState.success;
      } else if (result.message != null) {
        _state = _KrsMkLoadState.serverError;
      } else {
        _state = _KrsMkLoadState.noInternet;
      }
    });

    // EDOM gate (same flow as KHS / course offers): the student must
    // complete the lecturer evaluation before entering KRS.
    if (!result.cekEval) {
      _showEvalRequiredDialog();
    }

    if (_state == _KrsMkLoadState.success) {
      _autoCheckFromServer();
    }
  }

  /// Blocking dialog directing the student to complete EDOM first
  /// (general action-required dialog, same flow as the KHS page —
  /// the action replaces this page with the EDOM flow).
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

  /// Legacy adapter auto-check: for every course, the schedule with
  /// selected=="Y" becomes that course's pick (server truth).
  void _autoCheckFromServer() {
    _selected.clear();
    for (var i = 0; i < _makul.length; i++) {
      for (var j = 0; j < _makul[i].itemJadwal.length; j++) {
        if (_makul[i].itemJadwal[j].selected == 'Y') {
          _selected[i] = j;
          break;
        }
      }
    }
    setState(() {});
  }

  /// All picked schedules (for the conflict check + counters).
  Iterable<KrsJadwal> get _pickedJadwal =>
      _selected.entries.map((e) => _makul[e.key].itemJadwal[e.value]);

  int get _selectedMakulCount => _selected.length;

  int get _selectedTotalSks => _pickedJadwal.fold(0, (a, j) => a + j.sksMk);

  /// Payload excluding isacc=="Y" rows (legacy create_data_post()).
  List<KrsInputItem> _postPayload() => _pickedJadwal
      .where((j) => j.isacc != 'Y')
      .map(KrsInputItem.fromJadwal)
      .toList();

  void _onTapJadwal(int makulIndex, int jadwalIndex) {
    final makul = _makul[makulIndex];
    final jadwal = makul.itemJadwal[jadwalIndex];
    final l10n = AppLocalizations.of(context)!;

    final bool isCurrentlyPicked = _selected[makulIndex] == jadwalIndex;

    // Legacy: the conflict check runs BEFORE selecting, and only when the
    // row is not already selected ("T").
    if (!isCurrentlyPicked) {
      final conflict = findScheduleConflict(
        selected: _selected.entries
            .where((e) => e.key != makulIndex)
            .map(
              (e) => KrsSelectedSchedule(
                jadwalHari: _makul[e.key].itemJadwal[e.value].jadwalHari,
                jadwalJam: _makul[e.key].itemJadwal[e.value].jadwalJam,
                namaMakul: _makul[e.key].itemJadwal[e.value].makul,
              ),
            ),
        targetHari: jadwal.jadwalHari,
        targetJam: jadwal.jadwalJam,
        targetNamaMakul: jadwal.makul,
      );

      if (conflict != null) {
        AppNotifications.show(
          context,
          l10n.scheduleConflict(conflict),
          type: AppNotificationType.error,
        );
        return; // pick REJECTED (legacy behaviour)
      }
    }

    setState(() {
      if (isCurrentlyPicked) {
        _selected.remove(makulIndex); // uncheck
      } else {
        _selected[makulIndex] =
            jadwalIndex; // radio: replaces other class of same course
      }
    });
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

  Future<void> _submitKrs() async {
    final user = _sessionManager.getUser();
    final payload = _postPayload();
    if (user == null || payload.isEmpty) return;

    // Same payload shape as legacy Gson().toJson(create_data_post()).
    final dataJson = jsonEncode(payload.map((e) => e.toJson()).toList());

    _showSubmitLoadingDialog();

    final result = await _apiService.submitKrs(
      nim: user.nim ?? '',
      kdjen: user.kodeJen ?? '',
      kdpst: user.kodePst ?? '',
      dataJson: dataJson,

    );

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // close loading dialog

    _showResultDialog(
      success: result.success,
      message: result.message,
      onOk: () {
        if (result.success) _applyPostSubmit(result);
      },
    );
  }

  /// Legacy: on success re-bind the adapter from `response.data` (the fresh
  /// list — saved schedules now carry selected=="Y"), clear the selection and
  /// auto-check again.
  void _applyPostSubmit(KrsPostResponse result) {
    if (result.data == null) return;
    setState(() {
      _list = KrsListResponse(
        success: true,
        message: _list?.message,
        waktuMulai: _list?.waktuMulai,
        waktuSelesai: _list?.waktuSelesai,
        data: result.data,
      );
      _selected.clear();
    });
    _autoCheckFromServer();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    const mainGradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [Color(0xFF003D82), Color(0xFF0056B3)],
    );

    final bool hasList = _state == _KrsMkLoadState.success;

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
          l10n.inputKrsTitle,
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
      ),
      body: RefreshIndicator(
        onRefresh: _loadKrsMk,
        color: AppColors.primary,
        child: switch (_state) {
          _KrsMkLoadState.loading => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 300),
              Center(
                child: SpinKitThreeBounce(color: AppColors.primary, size: 30),
              ),
            ],
          ),
          _KrsMkLoadState.noData => ErrorStateWidget(
            type: ErrorStateType.noData,
            noDataMessage: l10n.noKrsOfferings,
            noDataIcon: Icons.post_add_rounded,
          ),
          _KrsMkLoadState.serverError => ErrorStateWidget(
            type: ErrorStateType.serverError,
            serverMessage: _list?.message,
          ),
          _KrsMkLoadState.noInternet => const ErrorStateWidget(
            type: ErrorStateType.noInternet,
          ),
          _KrsMkLoadState.success => ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
            itemCount: _makul.length + 1, // index 0 = info card
            itemBuilder: (context, index) {
              if (index == 0) return _buildInfoCard(l10n);
              return _buildMakulCard(index - 1, l10n);
            },
          ),
        },
      ),
      // Bottom summary + "Simpan" only when the list is loaded (legacy
      // disables the save button otherwise).
      bottomNavigationBar: hasList ? _buildBottomBar(l10n) : null,
    );
  }

  Widget _buildBottomBar(AppLocalizations l10n) {
    return Container(
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
                      l10n.krsTotalLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      l10n.selectedCoursesCount(
                        _selectedMakulCount,
                        _selectedTotalSks,
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _postPayload().isNotEmpty ? _submitKrs : null,
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
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(l10n.krsInputStartLabel, _list?.waktuMulai),
          const SizedBox(height: 8),
          _buildInfoRow(l10n.krsInputEndLabel, _list?.waktuSelesai),
          const Divider(height: 24, color: AppColors.iconBackground),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.secondary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.krsInputWarning,
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

  Widget _buildMakulCard(int makulIndex, AppLocalizations l10n) {
    final makul = _makul[makulIndex];

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
          // Header biru: makul (sks) / kode / semester (setara view_krs_mk.xml)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${makul.makul} (${makul.sksMk} ${l10n.credit})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n.courseCode} : ${makul.kodeMk}',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
                const SizedBox(height: 2),
                Text(
                  '${l10n.semester} : ${makul.semesterMk}',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          ...makul.itemJadwal.asMap().entries.map(
            (entry) =>
                _buildJadwalRow(makulIndex, entry.key, entry.value, l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildJadwalRow(
    int makulIndex,
    int jadwalIndex,
    KrsJadwal jadwal,
    AppLocalizations l10n,
  ) {
    final bool picked = _selected[makulIndex] == jadwalIndex;
    final bool disabled = jadwal.disabled;

    // Legacy "Sisa": the student's own pick counts toward the participants.
    final int sisa = jadwal.selected == 'Y'
        ? jadwal.kuota - (jadwal.jmlhPeserta + 1)
        : jadwal.kuota - jadwal.jmlhPeserta;

    final bool notScheduled =
        (jadwal.jadwalHari.isEmpty && jadwal.jadwalJam.isEmpty);

    final bool showApprovedBadge = picked && jadwal.isacc == 'Y';

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        jadwal.dosen,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (showApprovedBadge) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.bookmark_added_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.approvedBadge,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${l10n.classLabel} : ${jadwal.jadwalKelas}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${l10n.quotaLabel} : ${jadwal.kuota}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${l10n.remainingLabel} : $sisa',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: disabled ? AppColors.iconBackground : AppColors.info,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    notScheduled ? l10n.notScheduled : jadwal.waktu,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: disabled ? AppColors.textSecondary : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Same checkbox styling as input_offers_page.dart (primary check
          // color). IgnorePointer keeps the tap on the row InkWell (legacy:
          // non-clickable checkbox) while the checkbox still renders in the
          // active (non-disabled) color.
          IgnorePointer(
            child: Checkbox(
              value: picked,
              onChanged: (_) {}, // never called — pointer is ignored above
              activeColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );

    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: IgnorePointer(
        ignoring: disabled,
        child: Column(
          children: [
            InkWell(
              onTap: () => _onTapJadwal(makulIndex, jadwalIndex),
              child: content,
            ),
            const Divider(height: 1, color: AppColors.iconBackground),
          ],
        ),
      ),
    );
  }
}
