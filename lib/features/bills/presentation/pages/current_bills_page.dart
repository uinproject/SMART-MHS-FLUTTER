import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/session_manager.dart';
import '../models/tuition_bill_response.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'select_payment_method_page.dart';

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

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadBills());
  }

  Future<void> _loadBills() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final user = _sessionManager.getUser();
      if (user != null) {
        final result = await _apiService.getTuitionBills(
          nim: user.nim ?? '',
          kdjen: user.kodeJen ?? '',
          kdpst: user.kodePst ?? '',
          language: Localizations.localeOf(context).languageCode,
        );
        if (mounted) {
          setState(() {
            _bills = result;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
          l10n.bills,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: mainGradient),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadBills,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: SpinKitThreeBounce(color: AppColors.primary, size: 30))
            : _bills?.data == null || _bills!.data!.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _bills!.data!.length,
                    itemBuilder: (context, index) {
                      final semester = _bills!.data![index];
                      return _buildSemesterGroup(semester, l10n);
                    },
                  ),
      ),
      bottomNavigationBar: _isLoading || _bills?.data == null || _bills!.data!.isEmpty 
          ? null 
          : _buildBottomBar(currencyFormat, l10n),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long_rounded, size: 80, color: AppColors.primary.withValues(alpha: 0.1)),
              const SizedBox(height: 16),
              const Text('Tidak ada tagihan aktif', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSemesterGroup(SemesterBill semester, AppLocalizations l10n) {
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
        ...semester.itemTagihan.map((item) => _buildBillCard(item, l10n)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBillCard(BillItem item, AppLocalizations l10n) {
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
                const Text(
                  'BELUM LUNAS',
                  style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(item.jumlah),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(NumberFormat format, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Tagihan', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(
                  format.format(_calculateTotal()),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                  builder: (context) => SelectPaymentMethodPage(
                    totalAmount: _calculateTotal(),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(l10n.proceed, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
