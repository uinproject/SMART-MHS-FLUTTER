import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/session_manager.dart';
import '../../data/models/tuition_bill_response.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'select_payment_method_page.dart';
import 'payment_history_page.dart';

class CurrentBillsPage extends StatefulWidget {
  const CurrentBillsPage({super.key});

  @override
  State<CurrentBillsPage> createState() => _CurrentBillsPageState();
}

class _CurrentBillsPageState extends State<CurrentBillsPage> {
  final _apiService = ApiService();
  final _sessionManager = SessionManager();
  
  TuitionBillResponse? _bills;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadBills());
  }

  Future<void> _loadBills() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = _sessionManager.getUser();
    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Sesi berakhir. Silakan login kembali.";
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
        _isLoading = false;
        if (!result.success) {
          _errorMessage = result.message ?? "Terjadi kesalahan pada server.";
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Gagal memuat data. Periksa koneksi Anda.";
        });
      }
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
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    const mainGradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [Color(0xFF003D82), Color(0xFF0056B3)],
    );

    final bool hasBills = _bills?.data != null && _bills!.data!.isNotEmpty;

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
          l10n.tuitionFee,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: mainGradient)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentHistoryPage())),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadBills,
        child: _isLoading 
          ? const Center(child: SpinKitThreeBounce(color: AppColors.primary, size: 30))
          : _errorMessage != null 
            ? _buildErrorState(_errorMessage!)
            : !hasBills
              ? _buildEmptyState(l10n)
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _bills!.data!.length,
                  itemBuilder: (context, index) {
                    final semester = _bills!.data![index];
                    return _buildSemesterGroup(semester, l10n, currencyFormat);
                  },
                ),
      ),
      bottomNavigationBar: (!_isLoading && hasBills) ? _buildBottomBar(l10n, currencyFormat) : null,
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        const Icon(Icons.receipt_long_rounded, size: 80, color: Colors.black12),
        const SizedBox(height: 16),
        Center(child: Text(l10n.noActiveBills, style: const TextStyle(color: AppColors.textSecondary))),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        const Icon(Icons.error_outline_rounded, size: 80, color: AppColors.danger),
        const SizedBox(height: 16),
        Center(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
        )),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton(
            onPressed: _loadBills,
            child: const Text("Coba Lagi"),
          ),
        ),
      ],
    );
  }

  Widget _buildSemesterGroup(SemesterBill semester, AppLocalizations l10n, NumberFormat format) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text('${l10n.semester} ${semester.semester}'.toUpperCase(), 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
        ),
        ...semester.itemTagihan.map((item) => _buildBillCard(item, format)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBillCard(BillItem item, NumberFormat format) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.namatagihan, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('BELUM LUNAS', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(format.format(item.jumlah), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildBottomBar(AppLocalizations l10n, NumberFormat format) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Tagihan', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(format.format(_calculateTotal()), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => SelectPaymentMethodPage(totalAmount: _calculateTotal())
                )
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text(l10n.proceed, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
