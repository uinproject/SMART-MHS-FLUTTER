import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/session_manager.dart';
import '../../data/models/tuition_bill_response.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../widgets/error_state_widget.dart';
import 'select_payment_method_page.dart';
import 'payment_history_page.dart';

/// Load states — the uniform pattern shared with KRS/EDOM/schedule:
/// success / noData / serverMessage (API answered with a status+message,
/// informational) / serverError (API-level failure) / noInternet.
enum _BillsLoadState {
  loading,
  success,
  noData,
  serverMessage,
  serverError,
  noInternet,
}

class CurrentBillsPage extends StatefulWidget {
  const CurrentBillsPage({super.key});

  @override
  State<CurrentBillsPage> createState() => _CurrentBillsPageState();
}

class _CurrentBillsPageState extends State<CurrentBillsPage> {
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF003D82), Color(0xFF0056B3)],
  );

  final _apiService = ApiService();
  final _sessionManager = SessionManager();

  TuitionBillResponse? _bills;
  _BillsLoadState _state = _BillsLoadState.loading;

  /// Failure detail for the API-level error states: server `message` →
  /// concrete cause ("Error 500") → localized general message.
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadBills());
  }

  Future<void> _loadBills() async {
    if (!mounted) return;
    setState(() => _state = _BillsLoadState.loading);

    final user = _sessionManager.getUser();
    if (user == null) {
      if (mounted) {
        setState(() {
          _state = _BillsLoadState.serverError;
          _errorMessage = AppLocalizations.of(context)!.sessionExpired;
        });
      }
      return;
    }

    try {
      final result = await _apiService.getTuitionBills(
        nim: user.nim ?? '',
        kdjen: user.kodeJen ?? '',
        kdpst: user.kodePst ?? '',
      );

      if (!mounted) return;
      setState(() {
        _bills = result;
        if (result.success && result.data != null) {
          _state = result.data!.isEmpty
              ? _BillsLoadState.noData
              : _BillsLoadState.success;
        } else if (result.message != null && result.message!.isNotEmpty) {
          // The API ANSWERED with a status + message — informational, shown
          // with the regular (receipt) icon, not the error icon.
          _state = _BillsLoadState.serverMessage;
        } else {
          // Answered without a message — treat as connection-level failure.
          _state = _BillsLoadState.noInternet;
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
            ? _BillsLoadState.noInternet
            : _BillsLoadState.serverError;
      });
    }
  }

  int _calculateTotal() {
    if (_bills?.data == null) return 0;
    int total = 0;
    for (var semester in _bills!.data!) {
      for (var item in semester.itemTagihan) {
        total += item.jumlah;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    final bool hasBills =
        _state == _BillsLoadState.success && _bills!.data!.isNotEmpty;

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
          l10n.tuitionFee,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: mainGradient),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PaymentHistoryPage(),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      // Swipe-to-refresh retries a failed load (error/empty states stay
      // scrollable so the gesture always works).
      body: RefreshIndicator(
        onRefresh: _loadBills,
        color: AppColors.primary,
        child: switch (_state) {
          _BillsLoadState.loading => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.32),
              const Center(
                child: SpinKitThreeBounce(color: AppColors.primary, size: 30),
              ),
            ],
          ),
          _BillsLoadState.noData => ErrorStateWidget(
            type: ErrorStateType.noData,
            noDataMessage: l10n.noActiveBills,
          ),
          _BillsLoadState.serverMessage => ErrorStateWidget(
            type: ErrorStateType.noData,
            // API answered with a status+message → old (informational) icon.
            noDataMessage: _bills?.message,
            noDataIcon: Icons.receipt_long_rounded,
          ),
          _BillsLoadState.serverError => ErrorStateWidget(
            type: ErrorStateType.serverError,
            serverMessage: _errorMessage,
          ),
          _BillsLoadState.noInternet => const ErrorStateWidget(
            type: ErrorStateType.noInternet,
          ),
          _BillsLoadState.success => ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _bills!.data!.length,
            itemBuilder: (context, index) {
              final semester = _bills!.data![index];
              return _buildSemesterGroup(semester, l10n, currencyFormat);
            },
          ),
        },
      ),
      bottomNavigationBar: hasBills
          ? _buildBottomBar(l10n, currencyFormat)
          : null,
    );
  }

  Widget _buildSemesterGroup(
    SemesterBill semester,
    AppLocalizations l10n,
    NumberFormat format,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            '${l10n.semester} ${semester.semester}'.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...semester.itemTagihan.map(
          (item) => _buildBillCard(item, l10n, format),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBillCard(
    BillItem item,
    AppLocalizations l10n,
    NumberFormat format,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: mainGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
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
                      item.namatagihan,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildUnpaidPill(l10n),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  format.format(item.jumlah),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnpaidPill(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            l10n.billStatusUnpaid,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(AppLocalizations l10n, NumberFormat format) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        14 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.totalBills,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    format.format(_calculateTotal()),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Local minimumSize override — the global theme forces an infinite
          // min width which breaks buttons placed directly inside a Row.
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SelectPaymentMethodPage(totalAmount: _calculateTotal()),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 28),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Text(
              l10n.proceed,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
