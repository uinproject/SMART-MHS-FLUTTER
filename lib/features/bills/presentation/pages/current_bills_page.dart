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

/// Mirrors the legacy `TagihanFragment` business logic:
/// - loads bills on init (Future.microtask so context is ready)
/// - groups bills per semester
/// - total + "Lanjutkan" button only when there are bills
/// - payment history is reachable from the app bar (replaces legacy tabs)
/// - pull-to-refresh (legacy SwipeRefreshLayout)
/// Mirrors the legacy `TagihanFragment` business logic:
/// - loads bills on init (Future.microtask so context is ready)
/// - groups bills per semester
/// - total + "Lanjutkan" button only when there are bills
/// - payment history is reachable from the app bar (replaces legacy tabs)
/// - pull-to-refresh (legacy SwipeRefreshLayout)
enum _BillsLoadState { loading, success, noData, serverError, noInternet }

class CurrentBillsPage extends StatefulWidget {
  const CurrentBillsPage({super.key});

  @override
  State<CurrentBillsPage> createState() => _CurrentBillsPageState();
}

class _CurrentBillsPageState extends State<CurrentBillsPage> {
  final _apiService = ApiService();
  final _sessionManager = SessionManager();

  TuitionBillResponse? _bills;
  _BillsLoadState _state = _BillsLoadState.loading;

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
      if (mounted) setState(() => _state = _BillsLoadState.noInternet);
      return;
    }

    // NIM is filtered to digits-only inside the service (same as legacy).
    final result = await _apiService.getTuitionBills(
      nim: user.nim ?? '',
      kdjen: user.kodeJen ?? '',
      kdpst: user.kodePst ?? '',
    );

    if (!mounted) return;
    setState(() {
      _bills = result;
      if (result.success && result.data != null && result.data!.isNotEmpty) {
        _state = _BillsLoadState.success;
      } else if (result.success) {
        // legacy: success == true && data == null -> "Tidak ada tagihan yang harus dibayar"
        _state = _BillsLoadState.noData;
      } else if (result.message != null) {
        // legacy: success == false && message != null -> show server message
        _state = _BillsLoadState.serverError;
      } else {
        // legacy: onFailure -> no internet animation
        _state = _BillsLoadState.noInternet;
      }
    });
  }

  /// Same as legacy `PerhitunganKeuangan.totaltagihan()`: sum of every item.
  /// Same as legacy `PerhitunganKeuangan.totaltagihan()`: sum of every item.
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

  void _openPaymentHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PaymentHistoryPage()),
    );
  }

  void _openSelectPaymentMethod() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectPaymentMethodPage(totalAmount: _calculateTotal()),
      ),
    );
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

    final bool hasBills = _state == _BillsLoadState.success;

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
        // Legacy title: text_biaya_kuliah
        title: Text(
          l10n.tuitionFee,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: mainGradient),
        ),
        // Payment history entry point (replaces the legacy TabLayout),
        // styled like the semester filter pill in schedule_page.dart.
        actions: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openPaymentHistory,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                ),
                child: const Icon(Icons.history_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadBills,
        color: AppColors.primary,
        child: switch (_state) {
          _BillsLoadState.loading => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 300),
                Center(child: SpinKitThreeBounce(color: AppColors.primary, size: 30)),
              ],
            ),
          _BillsLoadState.noData => ErrorStateWidget(
              type: ErrorStateType.noData,
              noDataMessage: l10n.noActiveBills,
            ),
          _BillsLoadState.serverError => ErrorStateWidget(
              type: ErrorStateType.serverError,
              serverMessage: _bills?.message,
            ),
          _BillsLoadState.noInternet => const ErrorStateWidget(type: ErrorStateType.noInternet),
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
      // Bottom summary + "Lanjutkan" only when there are bills to pay
      // (legacy disables/hides the pay action when there is nothing to pay).
      bottomNavigationBar: hasBills
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
                            Text(l10n.totalBills,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                currencyFormat.format(_calculateTotal()),
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _openSelectPaymentMethod,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          // Override theme default minimumSize (double.infinity, 56):
                          // infinite min width breaks layout inside a Row.
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Text(l10n.proceed, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildSemesterGroup(SemesterBill semester, AppLocalizations l10n, NumberFormat format) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            '${l10n.semester} ${semester.semester}'.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary, letterSpacing: 1),
          ),
        ),
        ...semester.itemTagihan.map((item) => _buildBillCard(item, l10n, format)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBillCard(BillItem item, AppLocalizations l10n, NumberFormat format) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.namatagihan,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.billStatusUnpaid,
                  style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            format.format(item.jumlah),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
