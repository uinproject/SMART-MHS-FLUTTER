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
      _state =
          result.success && result.data != null ? _EdomMakulLoadState.success : _EdomMakulLoadState.serverError;
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
      EdomCoursesResult(statusApi: _statusApiEval, statusEval: _computedStatusEval),
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: _onWillPop,
          ),
          title: Text(
            l10n.edomCoursesTitle,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          centerTitle: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: mainGradient),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _loadCourses,
          color: AppColors.primary,
          child: switch (_state) {
            _EdomMakulLoadState.loading => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 300),
                  Center(child: SpinKitThreeBounce(color: AppColors.primary, size: 30)),
                ],
              ),
            _EdomMakulLoadState.serverError => ErrorStateWidget(
                type: ErrorStateType.serverError,
                serverMessage: _response?.message,
              ),
            _EdomMakulLoadState.success => ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                itemCount: _response!.data!.length,
                itemBuilder: (context, index) {
                  final makul = _response!.data![index];
                  return _buildMakulCard(makul, index, l10n);
                },
              ),
          },
        ),
      ),
    );
  }

  Widget _buildMakulCard(EdomMakulEval makul, int index, AppLocalizations l10n) {
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
              // Foto dosen with fallback to user_default asset (mirrors Glide .error(R.drawable.user_default))
              _buildDosenAvatar(makul.urlfotodoseneval),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      makul.namamkeval,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      makul.doseneval,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    // Badge status transparan (teks berwarna)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Rating bar (non-interactive) — mirrors Kotlin ratingbar.rating = makul.rating
          // Uses ClipRect for accurate fractional-star rendering
          _buildStarRating(makul.rating),
          // Komentar — hanya bila tidak kosong (legacy VISIBLE/GONE)
          if (makul.komentar.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                makul.komentar,
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Riwayat: hanya aktif bila sudah selesai
              TextButton(
                onPressed: isDone ? () => _openForm(makul, null) : null,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(l10n.edomHistoryButton),
              ),
              const SizedBox(width: 8),
              // Isi Penilaian: hanya aktif bila BELUM selesai
              ElevatedButton(
                onPressed: isDone ? null : () => _openForm(makul, index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.iconBackground,
                  disabledForegroundColor: AppColors.textSecondary,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(l10n.edomFillButton, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Foto dosen dengan fallback gambar user_default (setara Glide .error(R.drawable.user_default))
  Widget _buildDosenAvatar(String url) {
    if (url.isEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: AppColors.iconBackground,
        backgroundImage: const AssetImage('assets/images/user_default.png'),
      );
    }
    return CircleAvatar(
      radius: 28,
      backgroundColor: AppColors.iconBackground,
      foregroundImage: NetworkImage(url),
      onForegroundImageError: (_, __) {},
      backgroundImage: const AssetImage('assets/images/user_default.png'),
    );
  }

  /// Rating bar non-interaktif 5 bintang dengan clip akurat untuk partial-star
  Widget _buildStarRating(double rating) {
    const int total = 5;
    const double size = 22;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final double fill = (rating - i).clamp(0.0, 1.0);
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              const Icon(Icons.star_rounded, color: AppColors.iconBackground, size: size),
              ClipRect(
                clipper: _FractionalWidthClipper(fill),
                child: const Icon(Icons.star_rounded, color: Colors.amber, size: size),
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
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_FractionalWidthClipper old) => old.fraction != fraction;
}

