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
    final language = Localizations.localeOf(context).languageCode;
    setState(() => _state = _EdomSemLoadState.loading);

    final user = _sessionManager.getUser();
    if (user == null) {
      if (mounted) setState(() => _state = _EdomSemLoadState.serverError);
      return;
    }

    // NIM is hashed AS-IS (legacy EDOM does not digits-filter the NIM).
    final result = await _apiService.getEdomSemesters(
      nim: user.nim ?? '',
      language: language,
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
          items[index].keteranganStatus =
              AppLocalizations.of(context)!.edomStatusProgress;
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.edomSemestersTitle,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: mainGradient),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSemesters,
        color: AppColors.primary,
        child: switch (_state) {
          _EdomSemLoadState.loading => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 300),
                Center(child: SpinKitThreeBounce(color: AppColors.primary, size: 30)),
              ],
            ),
          _EdomSemLoadState.serverError => ErrorStateWidget(
              type: ErrorStateType.serverError,
              serverMessage: _response?.message,
            ),
          _EdomSemLoadState.success => ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              itemCount: _response!.data!.dataTahun.length,
              itemBuilder: (context, index) {
                final item = _response!.data!.dataTahun[index];
                return _buildSemesterCard(item, index, l10n);
              },
            ),
        },
      ),
    );
  }

  Widget _buildSemesterCard(EdomItemSemester item, int index, AppLocalizations l10n) {
    final (Color badgeColor, String badgeText) = switch (item.kodeStatusEval) {
      2 => (AppColors.success, l10n.edomStatusDone),
      1 => (AppColors.secondary, l10n.edomStatusProgress),
      _ => (AppColors.danger, l10n.edomStatusNotFilled),
    };

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
          // Header berwarna (setara ilustrasi evalbg legacy)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: const BoxDecoration(
              gradient: mainGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.semester} ${item.semester}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.keteranganStatus,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _openCourses(item, index),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.edomOpenDetail,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
