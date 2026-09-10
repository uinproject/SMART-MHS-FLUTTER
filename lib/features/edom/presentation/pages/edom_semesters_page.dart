import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/session_manager.dart';
import '../../../../core/utils/subscription_gate.dart';
import '../../data/models/edom_semester_response.dart';
import 'edom_courses_page.dart';
import '../../../bills/presentation/widgets/error_state_widget.dart';

/// Result popped by [EdomCoursesPage].
///
/// Mirrors the legacy Intent extras:
/// - statusapi
/// - statuseval
/// - position
class EdomCoursesResult {
  /// Whether the course list loaded successfully at least once (legacy:
  /// `statusapieval` — only then the semester status may be updated).
  final bool statusApi;

  /// "1" when any course is still un-evaluated / in progress, else "2".
  final String statusEval;

  const EdomCoursesResult({required this.statusApi, required this.statusEval});
}

/// Mirrors the legacy `PilihSemesterEvaluasiActivity` business logic:
/// - loads evaluation semesters on init (Future.microtask)
/// - subscription gate `ed@118` (dialog only)
/// - one card per semester: "Semester {n}" + status badge
///   (2 selesai / 1 proses / 0 belum) + "Isi / Detail Evaluasi" button
/// - awaits the courses page result and updates the item status locally
///   (without reload) when the old status is not "2" and it changed
/// - NOTE: no no-internet state — legacy EDOM always surfaces
///   "error ..." messages on connection failures
enum _EdomSemLoadState { loading, success, serverError }

class EdomSemestersPage extends StatefulWidget {
  const EdomSemestersPage({super.key});

  @override
  State<EdomSemestersPage> createState() => _EdomSemestersPageState();
}

class _EdomSemestersPageState extends State<EdomSemestersPage> {
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF003D82), Color(0xFF0056B3)],
  );

  final _apiService = ApiService();
  final _sessionManager = SessionManager();

  EdomSemestersResponse? _response;
  _EdomSemLoadState _state = _EdomSemLoadState.loading;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      checkSubscription(context, SubscriptionGateFeatures.edom);
      _loadSemesters();
    });
  }

  Future<void> _loadSemesters() async {
    if (!mounted) return;

    setState(() => _state = _EdomSemLoadState.loading);

    final user = _sessionManager.getUser();
    if (user == null) {
      if (mounted) setState(() => _state = _EdomSemLoadState.serverError);
      return;
    }

    // NIM is hashed AS-IS (legacy EDOM does not digits-filter the NIM).
    final result = await _apiService.getEdomSemesters(
      nim: user.nim ?? '',

    );

    if (!mounted) return;
    setState(() {
      _response = result;
      if (result.success && result.data != null) {
        _state = _EdomSemLoadState.success;
      } else {
        _state = _EdomSemLoadState.serverError;
      }
    });
  }

  /// Legacy resultLauncher logic: update the local item only when the old
  /// status is not 2 and it changed; "1" also rewrites the caption to the
  /// localized "Proses Pengisian".
  Future<void> _openCourses(EdomItemSemester item, int index) async {
    final result = await Navigator.push<EdomCoursesResult>(
      context,
      MaterialPageRoute(
        builder: (context) => EdomCoursesPage(item: item, index: index),
      ),
    );

    if (result == null || !result.statusApi) return;
    if (_state != _EdomSemLoadState.success) return;

    final items = _response!.data!.dataTahun;
    if (index >= items.length) return;
    final old = items[index].kodeStatusEval.toString();
    if (old != '2' && old != result.statusEval) {
      setState(() {
        items[index].kodeStatusEval = int.tryParse(result.statusEval) ?? 0;
        if (result.statusEval == '1') {
          items[index].keteranganStatus = AppLocalizations.of(
            context,
          )!.edomStatusProgress;
        }
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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.edomSemestersTitle,
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
        onRefresh: _loadSemesters,
        color: AppColors.primary,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: switch (_state) {
            _EdomSemLoadState.loading => ListView(
              key: const ValueKey('edom-loading'),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.32),
                const Center(
                  child: SpinKitThreeBounce(color: AppColors.primary, size: 30),
                ),
              ],
            ),
            _EdomSemLoadState.serverError => ErrorStateWidget(
              key: const ValueKey('edom-error'),
              type: ErrorStateType.serverError,
              serverMessage: _response?.message,
            ),
            _EdomSemLoadState.success =>
              _response?.data == null || _response!.data!.dataTahun.isEmpty
                  ? _buildEmptyState(l10n)
                  : ListView.builder(
                      key: const ValueKey('edom-semesters'),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      itemCount: _response!.data!.dataTahun.length + 1,
                      itemBuilder: (context, index) => index == 0
                          ? _buildProgressHeader(
                              l10n,
                              _response!.data!.dataTahun,
                            )
                          : _buildSemesterCard(
                              _response!.data!.dataTahun[index - 1],
                              index - 1,
                              l10n,
                            ),
                    ),
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return ListView(
      key: const ValueKey('edom-empty'),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.28),
        const Icon(
          Icons.event_note_rounded,
          size: 72,
          color: AppColors.iconBackground,
        ),
        const SizedBox(height: 16),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              l10n.edomSemestersEmpty,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Kartu ringkasan progres evaluasi (header daftar semester).
  Widget _buildProgressHeader(
    AppLocalizations l10n,
    List<EdomItemSemester> items,
  ) {
    final total = items.length;
    final done = items.where((item) => item.kodeStatusEval == 2).length;
    final progress = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);

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
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.task_alt_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.edomProgressSummary(done, total),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.edomSemestersSubtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TweenAnimationBuilder<double>(
            key: ValueKey('edom-progress-$done-$total'),
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterCard(
    EdomItemSemester item,
    int index,
    AppLocalizations l10n,
  ) {
    final (
      Color statusColor,
      String statusText,
    ) = switch (item.kodeStatusEval) {
      2 => (AppColors.success, l10n.edomStatusDone),
      1 => (AppColors.secondary, l10n.edomStatusProgress),
      _ => (AppColors.danger, l10n.edomStatusNotFilled),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        child: InkWell(
          onTap: () => _openCourses(item, index),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: mainGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(
                            '${l10n.semester} ${item.semester}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.keteranganStatus,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildStatusPill(statusColor, statusText),
                  ],
                ),
                const SizedBox(height: 14),
                _buildDetailButton(l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailButton(AppLocalizations l10n) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(
            Icons.rate_review_rounded,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.edomOpenDetail,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          Transform.flip(
            flipX: isRtl,
            child: const Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
    );
  }
}
