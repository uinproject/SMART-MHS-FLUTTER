import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/session_manager.dart';
import '../../data/models/payment_history_response.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../widgets/error_state_widget.dart';

/// Mirrors the legacy `RekapPembayaranFragment` business logic:
/// - loads payment history on init (Future.microtask so context is ready)
/// - fixed "Riwayat Pembayaran Tidak Ditemukan" message on failure (same as legacy)
/// - downloads the kuitansi PDF from the exact same URL as the legacy app,
///   then opens it (legacy used Android DownloadManager)
/// - pull-to-refresh (legacy SwipeRefreshLayout)
enum _HistoryLoadState { loading, success, noData, noInternet }

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  final _apiService = ApiService();
  final _sessionManager = SessionManager();

  PaymentHistoryResponse? _history;
  _HistoryLoadState _state = _HistoryLoadState.loading;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadHistory());
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() => _state = _HistoryLoadState.loading);
    final user = _sessionManager.getUser();
    if (user == null) {
      if (mounted) setState(() => _state = _HistoryLoadState.noInternet);
      return;
    }

    // NIM is filtered to digits-only inside the service (same as legacy).
    final result = await _apiService.getPaymentHistory(
      nim: user.nim ?? '',
      kdjen: user.kodeJen ?? '',
      kdpst: user.kodePst ?? '',
    );

    if (!mounted) return;
    setState(() {
      _history = result;
      if (result.success && result.data != null && result.data!.isNotEmpty) {
        _state = _HistoryLoadState.success;
      } else if (result.message != null) {
        // Legacy shows the FIXED string here (not the raw server message).
        _state = _HistoryLoadState.noData;
      } else {
        // legacy: onFailure -> no internet animation
        _state = _HistoryLoadState.noInternet;
      }
    });
  }

  /// Downloads the kuitansi PDF (same URL handling as legacy: `\/` -> `/`)
  /// and opens it. File name matches legacy:
  /// `kuitansi_{nim}_semester{semester}.pdf`.
  Future<void> _downloadReceipt(HistoryItem item) async {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.downloadingReceipt), duration: const Duration(seconds: 2)),
    );

    try {
      final user = _sessionManager.getUser();
      final fileName = 'kuitansi_${user?.nim ?? ''}_semester${item.semester}.pdf';
      final savedPath = await _apiService.downloadReceipt(
        url: item.linkKuitansi,
        fileName: fileName,
      );
      final result = await OpenFilex.open(savedPath);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.cantOpenReceipt)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.cantOpenReceipt)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

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
          l10n.paymentHistory,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: mainGradient),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        color: AppColors.primary,
        child: switch (_state) {
          _HistoryLoadState.loading => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 300),
                Center(child: SpinKitThreeBounce(color: AppColors.primary, size: 30)),
              ],
            ),
          _HistoryLoadState.noData => ErrorStateWidget(
              type: ErrorStateType.noData,
              noDataMessage: l10n.noPaymentHistoryFound,
              noDataIcon: Icons.history_rounded,
            ),
          _HistoryLoadState.noInternet => const ErrorStateWidget(type: ErrorStateType.noInternet),
          _HistoryLoadState.success => ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _history!.data!.length,
              itemBuilder: (context, index) {
                final item = _history!.data![index];
                return _buildHistoryCard(item, l10n, currencyFormat);
              },
            ),
        },
      ),
    );
  }

  Widget _buildHistoryCard(HistoryItem item, AppLocalizations l10n, NumberFormat format) {
    // Legacy: "{namatagihan} (Semester {semester})" only when semester is present.
    final title = item.semester.isEmpty
        ? item.namatagihan
        : l10n.historyItemDetail(item.namatagihan, item.semester);

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.billStatusPaid,
                  style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                item.tanggalbayar,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          // Legacy shows "Melalui : {melalui}"
          Text(
            '${l10n.via} : ${item.melalui}',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                format.format(item.jumlah),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
              ),
              if (item.linkKuitansi.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _downloadReceipt(item),
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: Text(l10n.downloadReceipt, style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
