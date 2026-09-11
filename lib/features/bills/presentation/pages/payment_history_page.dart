import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/session_manager.dart';
import '../../../../core/utils/app_notifications.dart';
import '../../data/models/payment_history_response.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../widgets/error_state_widget.dart';

/// Mirrors the legacy `RekapPembayaranFragment` business logic:
/// - loads payment history on init (Future.microtask so context is ready)
/// - downloads the kuitansi PDF from the exact same URL as the legacy app,
///   then opens it (legacy used Android DownloadManager)
/// - pull-to-refresh (legacy SwipeRefreshLayout). Uniform error handling:
/// an API ANSWER with status+message is informational (regular icon),
/// API-level failures (network / HTTP error) show the error icon.
enum _HistoryLoadState {
  loading,
  success,
  noData,
  serverMessage,
  serverError,
  noInternet,
}

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

  /// Failure detail for the API-level error states ("Error 500" / general).
  String? _errorMessage;

  final Map<String, double> _downloadProgress = {};
  final Map<String, String> _downloadedPaths = {};
  final Map<String, bool> _isDownloading = {};

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
      if (mounted) {
        setState(() {
          _state = _HistoryLoadState.serverError;
          _errorMessage = AppLocalizations.of(context)!.sessionExpired;
        });
      }
      return;
    }

    try {
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
        } else if (result.success) {
          _state = _HistoryLoadState.noData;
        } else if (result.message != null && result.message!.isNotEmpty) {
          // The API ANSWERED with a status + message — informational, shown
          // with the regular (history) icon, not the error icon.
          _state = _HistoryLoadState.serverMessage;
        } else {
          // Answered without a message — connection-level failure.
          _state = _HistoryLoadState.noInternet;
        }
      });
    } catch (e) {
      // The call itself failed (network / HTTP error / bad payload).
      if (!mounted) return;
      final failure = ApiService.describeFailure(e);
      setState(() {
        _errorMessage =
            failure ?? AppLocalizations.of(context)!.errorResponseApi;
        _state = failure == null
            ? _HistoryLoadState.noInternet
            : _HistoryLoadState.serverError;
      });
    }
  }

  /// Downloads the kuitansi PDF (same URL handling as legacy: `\/` -> `/`)
  /// with real-time progress indicator and opens it. File name matches legacy:
  /// `kuitansi_{nim}_semester{semester}.pdf`.
  Future<void> _downloadReceipt(HistoryItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final user = _sessionManager.getUser();
    final fileName =
        'kuitansi_${user?.nim ?? ''}_semester${item.semester}.pdf';
    final key = item.semester.toString();

    setState(() {
      _isDownloading[key] = true;
      _downloadProgress[key] = 0.0;
    });

    try {
      final savedPath = await _apiService.downloadReceipt(
        url: item.linkKuitansi,
        fileName: fileName,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() {
              _downloadProgress[key] = (received / total).clamp(0.0, 1.0);
            });
          }
        },
      );

      if (!mounted) return;

      setState(() {
        _isDownloading[key] = false;
        _downloadProgress[key] = 1.0;
        _downloadedPaths[key] = savedPath;
      });

      final result = await OpenFilex.open(savedPath);
      if (result.type != ResultType.done && mounted) {
        AppNotifications.show(
          context,
          l10n.cantOpenReceipt,
          type: AppNotificationType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDownloading[key] = false;
      });
      AppNotifications.show(
        context,
        l10n.cantOpenReceipt,
        type: AppNotificationType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

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
          l10n.paymentHistory,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        color: AppColors.primary,
        child: switch (_state) {
          _HistoryLoadState.loading => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 300),
              Center(
                child: SpinKitThreeBounce(color: AppColors.primary, size: 30),
              ),
            ],
          ),
          _HistoryLoadState.noData => ErrorStateWidget(
            type: ErrorStateType.noData,
            noDataMessage: l10n.noPaymentHistoryFound,
            noDataIcon: Icons.history_rounded,
          ),
          _HistoryLoadState.serverMessage => ErrorStateWidget(
            type: ErrorStateType.noData,
            // API answered with status+message → old (informational) icon.
            noDataMessage: _history?.message,
            noDataIcon: Icons.history_rounded,
          ),
          _HistoryLoadState.serverError => ErrorStateWidget(
            type: ErrorStateType.serverError,
            serverMessage: _errorMessage,
          ),
          _HistoryLoadState.noInternet => const ErrorStateWidget(
            type: ErrorStateType.noInternet,
          ),
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

  Widget _buildHistoryCard(
    HistoryItem item,
    AppLocalizations l10n,
    NumberFormat format,
  ) {
    // Legacy: "{namatagihan} (Semester {semester})" only when semester is present.
    final title = item.semester.isEmpty
        ? item.namatagihan
        : l10n.historyItemDetail(item.namatagihan, item.semester);

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
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
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
                              Icons.payments_rounded,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${l10n.via}: ${item.melalui}',
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
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildPaidPill(l10n),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.tanggalbayar,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  format.format(item.jumlah),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (item.linkKuitansi.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 14),
                _buildDownloadSection(l10n, item),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaidPill(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            l10n.billStatusPaid,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadSection(AppLocalizations l10n, HistoryItem item) {
    final key = item.semester.toString();
    final bool isDownloading = _isDownloading[key] == true;
    final double progress = _downloadProgress[key] ?? 0.0;
    final String? downloadedPath = _downloadedPaths[key];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progress bar + persentase (tampil saat sedang mengunduh)
        if (isDownloading) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.downloadingReceipt,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],

        // Tombol: Buka File (setelah selesai) atau Unduh Kuitansi
        if (downloadedPath != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => OpenFilex.open(downloadedPath),
              icon: const Icon(Icons.file_open_rounded, size: 18, color: Colors.white),
              label: Text(
                l10n.openFile,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isDownloading ? null : () => _downloadReceipt(item),
              icon: isDownloading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.download_rounded, size: 18, color: Colors.white),
              label: Text(
                l10n.downloadReceipt,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
