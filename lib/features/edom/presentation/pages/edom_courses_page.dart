import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/session_manager.dart';
import '../../../../core/utils/subscription_gate.dart';
import '../../data/models/edom_semester_response.dart';
import '../../data/models/edom_makul_response.dart';
import 'edom_form_page.dart';
import 'edom_semesters_page.dart' show EdomCoursesResult;
import '../../../bills/presentation/widgets/error_state_widget.dart';

/// Result popped by [EdomFormPage] after a successful submit — mirrors the
/// legacy Intent extras ("statuseval", "rating", "komentar").
class EdomFormResult {
  final double rating;
  final String komentar;

  const EdomFormResult({required this.rating, required this.komentar});
}

/// Mirrors the legacy `PilihMakulEvaluasiActivity` business logic:
/// - loads the evaluated courses of a semester (Future.microtask, hashed thsms)
/// - subscription gate `ed@118` (dialog only)
/// - card per course: lecturer photo (with fallback), name, status badge,
///   lecturer name, star rating (non-interactive) and the given comment
///   (only when non-empty — legacy VISIBLE/GONE)
/// - "Riwayat" button enabled ONLY for statuseval == "2" (view-only form)
/// - "Isi Penilaian" enabled ONLY for statuseval != "2"; on success the
///   local item is updated with status "2" + rating + komentar
/// - back -> pops EdomCoursesResult for the semester page (legacy:
///   statusApi = last successful load; statusEval "1" when any course is
///   "0"/"1", else "2")
enum _EdomMakulLoadState { loading, success, serverError }

class EdomCoursesPage extends StatefulWidget {
  final EdomItemSemester item;

  /// Index of this semester in the parent list (result chain).
  final int index;

  const EdomCoursesPage({super.key, required this.item, required this.index});

  @override
  State<EdomCoursesPage> createState() => _EdomCoursesPageState();
}

class _EdomCoursesPageState extends State<EdomCoursesPage> {
  final _apiService = ApiService();
  final _sessionManager = SessionManager();

  EdomCoursesResponse? _response;
  _EdomMakulLoadState _state = _EdomMakulLoadState.loading;

  /// Legacy `statusapieval`: true when the last load succeeded — gates the
  /// semester-status update on the parent page.
  bool _statusApiEval = false;

  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF003D82), Color(0xFF0056B3)],
  );

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      checkSubscription(context, SubscriptionGateFeatures.edom);
      _loadCourses();
    });
  }

  Future<void> _loadCourses() async {
    if (!mounted) return;
    final language = Localizations.localeOf(context).languageCode;
    setState(() => _state = _EdomMakulLoadState.loading);

    final user = _sessionManager.getUser();
    if (user == null) {
      if (mounted) setState(() => _state = _EdomMakulLoadState.serverError);
      return;
    }

    final result = await _apiService.getEdomCourses(
      nim: user.nim ?? '',
      thsms: widget.item.thsms,
      language: language,
    );

    if (!mounted) return;
    setState(() {
      _response = result;
      _statusApiEval = result.success;
      _state = result.success && result.data != null
          ? _EdomMakulLoadState.success
          : _EdomMakulLoadState.serverError;
    });
  }

  /// Legacy computes the semester status when LEAVING the page.
  String get _computedStatusEval {
    final data = _response?.data;
    if (data != null) {
      for (final it in data) {
        if (it.statusEval == '1' || it.statusEval == '0') return '1';
      }
    }
    return '2';
  }

  void _onWillPop() {
    Navigator.pop(
      context,
      EdomCoursesResult(
        statusApi: _statusApiEval,
        statusEval: _computedStatusEval,
      ),
    );
  }

  Future<void> _openForm(EdomMakulEval makul, int? index) async {
    final result = await Navigator.push<EdomFormResult>(
      context,
      MaterialPageRoute(
        builder: (context) => EdomFormPage(makul: makul, index: index),
      ),
    );

    // Legacy resultLauncher: update the local item only when the old status
    // is not "2" (the popped status is always "2" — only returned after a
    // successful submit).
    if (result == null) return;
    if (_state != _EdomMakulLoadState.success || index == null) return;
    final items = _response!.data!;
    if (index >= items.length) return;
    final old = items[index].statusEval;
    if (old != '2') {
      setState(() {
        items[index].statusEval = '2';
        items[index].rating = result.rating;
        items[index].komentar = result.komentar;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _onWillPop();
      },
      child: Scaffold(
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
            onPressed: _onWillPop,
          ),
          title: Text(
            l10n.edomCoursesTitle,
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
          onRefresh: _loadCourses,
          color: AppColors.primary,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: switch (_state) {
              _EdomMakulLoadState.loading => ListView(
                key: const ValueKey('edom-courses-loading'),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.32),
                  const Center(
                    child: SpinKitThreeBounce(
                      color: AppColors.primary,
                      size: 30,
                    ),
                  ),
                ],
              ),
              _EdomMakulLoadState.serverError => ErrorStateWidget(
                key: const ValueKey('edom-courses-error'),
                type: ErrorStateType.serverError,
                serverMessage: _response?.message,
              ),
              _EdomMakulLoadState.success =>
                _response?.data == null || _response!.data!.isEmpty
                    ? _buildEmptyState(l10n)
                    : ListView.builder(
                        key: const ValueKey('edom-courses'),
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                        itemCount: _response!.data!.length + 1,
                        itemBuilder: (context, index) => index == 0
                            ? _buildProgressHeader(l10n, _response!.data!)
                            : _buildMakulCard(
                                _response!.data![index - 1],
                                index - 1,
                                l10n,
                              ),
                      ),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return ListView(
      key: const ValueKey('edom-courses-empty'),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.28),
        const Icon(
          Icons.menu_book_rounded,
          size: 72,
          color: AppColors.iconBackground,
        ),
        const SizedBox(height: 16),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              l10n.edomCoursesEmpty,
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

  /// Kartu ringkasan progres evaluasi mata kuliah (header daftar).
  Widget _buildProgressHeader(
    AppLocalizations l10n,
    List<EdomMakulEval> items,
  ) {
    final total = items.length;
    final done = items.where((m) => m.statusEval == '2').length;
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
                  Icons.menu_book_rounded,
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
                      l10n.edomCoursesProgressSummary(done, total),
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
                      '${l10n.semester} ${widget.item.semester}',
                      maxLines: 1,
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
            key: ValueKey('edom-courses-progress-$done-$total'),
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

  Widget _buildMakulCard(
    EdomMakulEval makul,
    int index,
    AppLocalizations l10n,
  ) {
    // Mirror Kotlin MakulEvalAdapter status colors exactly:
    // statuseval == "2" → green  (circle_object_success_transparan)
    // statuseval == "1" → blue   (circle_object_info_transparan)
    // else              → orange (circle_object_warning_transparan)
    final (Color statusColor, String statusText) = switch (makul.statusEval) {
      '2' => (AppColors.success, l10n.edomStatusDone),
      '1' => (AppColors.info, l10n.edomStatusProgress),
      _ => (AppColors.secondary, l10n.edomStatusNotFilled),
    };

    final bool isDone = makul.statusEval == '2';

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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Foto dosen with fallback to user_default asset (mirrors Glide .error(R.drawable.user_default))
                  _buildDosenAvatar(makul.urlfotodoseneval),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          makul.namamkeval,
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
                                makul.doseneval,
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
                        const SizedBox(height: 8),
                        _buildStatusPill(statusColor, statusText),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Rating bar (non-interactive) — mirrors Kotlin ratingbar.rating = makul.rating
              // Uses ClipRect for accurate fractional-star rendering
              Row(
                children: [
                  _buildStarRating(makul.rating),
                  if (makul.rating > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      makul.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ],
                ],
              ),
              // Komentar — hanya bila tidak kosong (legacy VISIBLE/GONE)
              if (makul.komentar.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.format_quote_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          makul.komentar,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Divider(
                height: 28,
                thickness: 1,
                color: AppColors.background,
              ),
              // Riwayat: hanya aktif bila sudah selesai; Isi Penilaian: bila belum.
              _buildActionButtons(
                l10n,
                isDone,
                onHistory: () => _openForm(makul, null),
                onFill: () => _openForm(makul, index),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    AppLocalizations l10n,
    bool isDone, {
    required VoidCallback onHistory,
    required VoidCallback onFill,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isDone ? onHistory : null,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(
                width: 1.3,
                color: isDone ? AppColors.primary : AppColors.iconBackground,
              ),
              foregroundColor: AppColors.primary,
              disabledForegroundColor: AppColors.textSecondary.withValues(
                alpha: 0.45,
              ),
            ),
            icon: const Icon(Icons.history_rounded, size: 17),
            label: Text(
              l10n.edomHistoryButton,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isDone ? null : onFill,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.iconBackground,
              disabledForegroundColor: AppColors.textSecondary.withValues(
                alpha: 0.55,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.rate_review_rounded, size: 17),
            label: Text(
              l10n.edomFillButton,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Foto dosen dengan ring gradient & fallback gambar user_default
  /// (setara Glide .error(R.drawable.user_default))
  Widget _buildDosenAvatar(String url) {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: mainGradient,
      ),
      child: CircleAvatar(
        radius: 27,
        backgroundColor: AppColors.iconBackground,
        foregroundImage: url.isEmpty ? null : NetworkImage(url),
        onForegroundImageError: url.isEmpty ? null : (_, __) {},
        backgroundImage: const AssetImage('assets/images/user_default.png'),
      ),
    );
  }

  /// Rating bar non-interaktif 5 bintang dengan clip akurat untuk partial-star
  Widget _buildStarRating(double rating) {
    const int total = 5;
    const double size = 20;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final double fill = (rating - i).clamp(0.0, 1.0);
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              const Icon(
                Icons.star_rounded,
                color: AppColors.iconBackground,
                size: size,
              ),
              ClipRect(
                clipper: _FractionalWidthClipper(fill),
                child: const Icon(
                  Icons.star_rounded,
                  color: Colors.amber,
                  size: size,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Clips a widget to a fractional width — used for partial-star rating display.
class _FractionalWidthClipper extends CustomClipper<Rect> {
  final double fraction;
  const _FractionalWidthClipper(this.fraction);

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_FractionalWidthClipper old) => old.fraction != fraction;
}
