import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/session_manager.dart';
import '../models/tagihan_response.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../pages/select_payment_method_page.dart';

class CurrentBillsView extends StatefulWidget {
  const CurrentBillsView({super.key});

  @override
  State<CurrentBillsView> createState() => _CurrentBillsViewState();
}

class _CurrentBillsViewState extends State<CurrentBillsView> {
  final _apiService = ApiService();
  final _sessionManager = SessionManager();
  
  TagihanResponse? _tagihan;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    setState(() => _isLoading = true);
    try {
      final user = _sessionManager.getUser();
      if (user != null) {
        final result = await _apiService.getTagihanmhs(
          nim: user.nim ?? '',
          language: Localizations.localeOf(context).languageCode,
        );
        if (mounted) {
          setState(() {
            _tagihan = result;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _calculateTotal() {
    if (_tagihan?.itemTagihan == null) return 0;
    return _tagihan!.itemTagihan!.fold(0, (sum, item) => sum + item.nominalInt);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    if (_isLoading) {
      return const Center(child: SpinKitThreeBounce(color: AppColors.primary, size: 30));
    }

    if (_tagihan?.itemTagihan == null || _tagihan!.itemTagihan!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded, size: 80, color: AppColors.primary.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            const Text('Tidak ada tagihan aktif', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _tagihan!.itemTagihan!.length,
            itemBuilder: (context, index) {
              final item = _tagihan!.itemTagihan![index];
              return _buildBillCard(item, l10n);
            },
          ),
        ),
        _buildBottomBar(currencyFormat, l10n),
      ],
    );
  }

  Widget _buildBillCard(ItemTagihan item, AppLocalizations l10n) {
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
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.status.toUpperCase(),
                  style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const Icon(Icons.payment_rounded, size: 20, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.uraian,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Rp ${item.nominal}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
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
          Column(
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
