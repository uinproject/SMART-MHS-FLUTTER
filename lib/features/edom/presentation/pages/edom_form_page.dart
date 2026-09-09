import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/session_manager.dart';
import '../../../../core/utils/subscription_gate.dart';
import '../../data/models/edom_makul_response.dart';
import '../../data/models/edom_soal_response.dart';
import '../../data/models/edom_post_models.dart';
import '../../data/edom_eval_validator.dart';
import 'edom_courses_page.dart' show EdomFormResult;
import '../../../bills/presentation/widgets/error_state_widget.dart';

/// Mirrors the legacy `PenilaianMakulEvaluasiActivity` business logic:
/// - loads the evaluation questions of one course (Future.microtask)
/// - subscription gate `ed@118` (dialog only)
/// - header: lecturer photo + name; indicator chips; one question per
///   PageView page with radio answers; global progress "{n} / {total}"
/// - Next on the last question of the last indicator -> validate ALL
///   questions (first gap reported) -> "Kesan Pesan" dialog (comment min
///   8 chars, kept when reopened) -> hashed JSON POST -> success dialog
///   -> pop EdomFormResult (rating + komentar)
/// - back before submitting -> confirm dialog "answers will not be saved"
///   and pop WITHOUT a result (legacy behaviour)
/// - viewOnly (Riwayat): everything read-only, Next disabled at the end
/// - NOTE (agreed deviation): questions render for ANY number of
///   indicators (legacy only rendered when > 1 — a bug)
enum _EdomFormLoadState { loading, success, serverError }

class EdomFormPage extends StatefulWidget {
  final EdomMakulEval makul;

  /// Position of the course in the courses list; null = view-only history
  /// mode (legacy "viewrw").
  final int? index;

  const EdomFormPage({super.key, required this.makul, this.index});

  @override
  State<EdomFormPage> createState() => _EdomFormPageState();
}

class _EdomFormPageState extends State<EdomFormPage> {
  final _apiService = ApiService();
  final _sessionManager = SessionManager();

  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF003D82), Color(0xFF0056B3)],
  );

  List<EdomIndikator> _indikators = [];
  _EdomFormLoadState _state = _EdomFormLoadState.loading;

  bool get _viewOnly => widget.index == null;

  /// Active indicator index + page controller for the question pager.
  int _activeIndikator = 0;
  PageController? _pageController;

  /// Global question offset per indicator (legacy `numstartindex`).
  late List<int> _startIndexes;

  /// Total questions across all indicators (legacy `dataSize`).
  int _totalSoal = 0;

  /// Draft comment kept between dialog reopens (legacy `saransaved`).
  String _saranSaved = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      checkSubscription(context, SubscriptionGateFeatures.edom);
      _loadQuestions();
    });
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    if (!mounted) return;
    final language = Localizations.localeOf(context).languageCode;
    setState(() => _state = _EdomFormLoadState.loading);

    final result = await _apiService.getEdomQuestions(
      ideval: widget.makul.ideval,
      language: language,
    );

    if (!mounted) return;
    setState(() {
      if (result.success && result.data != null && result.data!.isNotEmpty) {
        _indikators = result.data!;
        _computeStartIndexes();
        _pageController?.dispose();
        _pageController = PageController();
        _state = _EdomFormLoadState.success;
      } else {
        _indikators = [];
        _state = _EdomFormLoadState.serverError;
      }
    });
  }

  void _computeStartIndexes() {
    _startIndexes = [];
    var acc = 0;
    for (final ind in _indikators) {
      _startIndexes.add(acc);
      acc += ind.itemsoal.length;
    }
    _totalSoal = acc;
  }

  int get _activeSoalCount => _indikators[_activeIndikator].itemsoal.length;
  int get _maxIndikator => _indikators.length - 1;

  void _selectIndikator(int index) {
    setState(() => _activeIndikator = index);
    _pageController!.jumpToPage(0);
  }

  void _next() {
    final page = _pageController!.page?.round() ?? 0;
    if (page < _activeSoalCount - 1) {
      _pageController!.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else if (_activeIndikator < _maxIndikator) {
      setState(() => _activeIndikator++);
      _pageController!.jumpToPage(0);
    } else {
      // Last question of the last indicator -> validate & submit
      // (read-only mode: nothing to do — button is disabled).
      if (!_viewOnly) _validateAndContinue();
    }
  }

  void _previous() {
    final page = _pageController!.page?.round() ?? 0;
    if (page > 0) {
      _pageController!.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else if (_activeIndikator > 0) {
      setState(() => _activeIndikator--);
      // Jump to the LAST question of the previous indicator (legacy prev_data).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController != null) {
          _pageController!.jumpToPage(_activeSoalCount - 1);
        }
      });
    }
  }

  void _answerQuestion(EdomSoal soal, EdomJawaban picked) {
    if (_viewOnly) return;
    setState(() {
      for (final j in soal.itemjawaban) {
        j.terjawab = 'N';
      }
      // Legacy allows tapping the selected answer again to unselect it.
      picked.terjawab = picked.terjawab == 'Y' ? 'N' : 'Y';
    });
  }

  // ---- Validation & submit (port create_data_post + show_komentar + apiposteval)

  void _validateAndContinue() {
    final l10n = AppLocalizations.of(context)!;
    final result = EdomEvalValidator.buildEdomPayload(
      indicators: _indikators,
      errorTemplate: (indicator, number) =>
          l10n.edomFillAllQuestionsError(indicator, number),
    );

    if (!result.validate) {
      _showMessageDialog(result.errorMessage, isError: true);
      return;
    }
    _showKomentarDialog(l10n, result.payload);
  }

  void _showKomentarDialog(AppLocalizations l10n, List<EdomPostItem> payload) {
    final controller = TextEditingController(text: _saranSaved);
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.edomImpressionTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.edomImpressionInstruction,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: l10n.edomImpressionTitle,
                    errorText: errorText,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                  onChanged: (_) {
                    if (errorText != null) {
                      setDialogState(() => errorText = null);
                    }
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final saran = controller.text.trim();
                      // Legacy CustomValidation.seterrorvalidation_on_saran: min 8 chars.
                      if (saran.length < 8) {
                        setDialogState(
                          () => errorText = l10n.edomImpressionMinError,
                        );
                        return;
                      }
                      _saranSaved = saran; // legacy keeps the draft
                      Navigator.pop(dialogContext);
                      _submit(payload, saran);
                    },
                    child: Text(l10n.okButton),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(List<EdomPostItem> payload, String saran) async {
    final l10n = AppLocalizations.of(context)!;
    final user = _sessionManager.getUser();
    if (user == null) return;

    final data = EdomPostData(
      nim: user.nim ?? '',
      validate: true,
      errorvalidatemessage: '',
      language: Localizations.localeOf(context).languageCode,
      datapost: payload,
      saran: saran,
      ideval: widget.makul.ideval,
    );

    // Loading dialog (legacy: flying-plane + "Menyimpan jawaban anda").
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
                  l10n.edomSaving,
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

    final result = await _apiService.submitEdomEvaluation(
      dataJson: jsonEncode(data.toJson()),
    );

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // close loading dialog

    if (result.success && result.message.isNotEmpty) {
      _showMessageDialog(
        result.message,
        isSuccess: true,
        onOk: () => Navigator.pop(
          context,
          EdomFormResult(
            rating: result.rating ?? 0.0,
            komentar: result.komentar,
          ),
        ),
      );
    } else {
      _showMessageDialog(
        result.message.isNotEmpty ? result.message : l10n.errorResponseApi,
        isError: true,
      );
    }
  }

  void _showMessageDialog(
    String message, {
    bool isError = false,
    bool isSuccess = false,
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
                  color: (isSuccess ? AppColors.success : AppColors.danger)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: isSuccess ? AppColors.success : AppColors.danger,
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

  /// Port of `exit_confirm`: leaving without submitting asks for
  /// confirmation (view-only mode exits directly).
  Future<bool> _confirmExit() async {
    if (_viewOnly) return true;
    final l10n = AppLocalizations.of(context)!;
    final bool? leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.help_outline_rounded,
                  color: AppColors.danger,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.edomExitConfirmTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.edomExitConfirmMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(l10n.ok),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmExit()) {
          if (context.mounted) Navigator.pop(context);
        }
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
            onPressed: () async {
              if (await _confirmExit() && context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            _viewOnly ? l10n.edomHistoryButton : l10n.edomFillButton,
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
        body: switch (_state) {
          _EdomFormLoadState.loading => const Center(
            child: SpinKitThreeBounce(color: AppColors.primary, size: 30),
          ),
          _EdomFormLoadState.serverError => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              ErrorStateWidget(
                type: ErrorStateType.serverError,
                serverMessage: null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ElevatedButton(
                  onPressed: _loadQuestions,
                  child: Text(l10n.tryAgain),
                ),
              ),
            ],
          ),
          _EdomFormLoadState.success => Column(
            children: [
              _buildHeader(l10n),
              _buildIndikatorChips(),
              Expanded(child: _buildQuestionPager()),
              _buildProgressBar(),
              _buildNavButtons(l10n),
            ],
          ),
        },
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(gradient: mainGradient),
      child: Row(
        children: [
          // Foto dosen dengan fallback user_default — sama seperti edom_courses_page
          // (setara Glide .error(R.drawable.user_default)); ring putih frosted
          // agar terlihat di atas header gradient.
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            child: CircleAvatar(
              radius: 21.5,
              backgroundColor: AppColors.iconBackground,
              foregroundImage: widget.makul.urlfotodoseneval.isEmpty
                  ? null
                  : NetworkImage(widget.makul.urlfotodoseneval),
              onForegroundImageError: widget.makul.urlfotodoseneval.isEmpty
                  ? null
                  : (_, __) {},
              backgroundImage: const AssetImage(
                'assets/images/user_default.png',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.makul.namamkeval,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.makul.doseneval,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndikatorChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _indikators.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final active = index == _activeIndikator;
            return ChoiceChip(
              label: Text(_indikators[index].namakompetensi),
              selected: active,
              onSelected: _viewOnly ? null : (_) => _selectIndikator(index),
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: active ? AppColors.primary : AppColors.iconBackground,
              ),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: active ? Colors.white : AppColors.textPrimary,
              ),
              showCheckmark: false,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuestionPager() {
    return PageView.builder(
      controller: _pageController,
      itemCount: _activeSoalCount,
      onPageChanged: (_) => setState(() {}), // refresh progress index
      itemBuilder: (context, page) {
        final soal = _indikators[_activeIndikator].itemsoal[page];
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${page + 1}. ${soal.pertanyaan}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
              if (soal.urlimage != null && soal.urlimage!.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    soal.urlimage!,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ...soal.itemjawaban.map(
                (jawaban) => _buildAnswerOption(soal, jawaban),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnswerOption(EdomSoal soal, EdomJawaban jawaban) {
    final bool selected = jawaban.terjawab == 'Y';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.iconBackground,
          width: selected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _viewOnly
              ? null
              : () {
                  _answerQuestion(soal, jawaban);
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.panorama_fish_eye_rounded,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                if (jawaban.indexpilihan.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : AppColors.iconBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      jawaban.indexpilihan,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: selected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    jawaban.pilihan,
                    style: TextStyle(
                      fontSize: 13,
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final page = _pageController?.hasClients == true
        ? _pageController!.page?.round() ?? 0
        : 0;
    final current = _startIndexes[_activeIndikator] + page + 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$current / $_totalSoal',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Legacy: progress = current global index, max = total - 1.
          LinearProgressIndicator(
            value: _totalSoal <= 1 ? 1 : (current - 1) / (_totalSoal - 1),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
            backgroundColor: AppColors.iconBackground,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildNavButtons(AppLocalizations l10n) {
    final page = _pageController?.hasClients == true
        ? _pageController!.page?.round() ?? 0
        : 0;
    final bool atVeryEnd =
        _activeIndikator == _maxIndikator && page == _activeSoalCount - 1;
    final bool showSave = atVeryEnd && !_viewOnly;

    // Legacy: in view-only mode the Next button is disabled at the very end.
    final bool nextEnabled = !(atVeryEnd && _viewOnly);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _previous,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: nextEnabled ? _next : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.iconBackground,
                disabledForegroundColor: AppColors.textSecondary,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    showSave ? l10n.save : '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Icon(
                    showSave
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
