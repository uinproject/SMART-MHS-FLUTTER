import 'package:flutter/material.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/session_manager.dart';
import '../../data/models/payment_method_response.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../widgets/error_state_widget.dart';
import 'payment_instruction_page.dart';

/// Mirrors the legacy `MetodePembayaranActivity` business logic:
/// - loads payment methods on create (Future.microtask so context is ready)
/// - sends the `language` field (legacy does send it for this endpoint)
/// - tap a method -> detail/instructions page with the total amount
/// - pull-to-refresh (legacy SwipeRefreshLayout)
enum _MethodLoadState { loading, success, noData, serverError, noInternet }

class SelectPaymentMethodPage extends StatefulWidget {
  final int totalAmount;
  const SelectPaymentMethodPage({super.key, required this.totalAmount});

  @override
  State<SelectPaymentMethodPage> createState() => _SelectPaymentMethodPageState();
}

class _SelectPaymentMethodPageState extends State<SelectPaymentMethodPage> {
  final _apiService = ApiService();
  final _sessionManager = SessionManager();

  PaymentMethodResponse? _methods;
  _MethodLoadState _state = _MethodLoadState.loading;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadMethods());
  }

  Future<void> _loadMethods() async {
    if (!mounted) return;
    setState(() => _state = _MethodLoadState.loading);
    final user = _sessionManager.getUser();
    if (user == null) {
      if (mounted) setState(() => _state = _MethodLoadState.noInternet);
      return;
    }

    // NIM is filtered to digits-only inside the service (same as legacy).
    // Legacy sends the language field for this endpoint (unlike tagihan/rekap).
    final result = await _apiService.getPaymentMethods(
      nim: user.nim ?? '',
      language: Localizations.localeOf(context).languageCode,
    );

    if (!mounted) return;
    setState(() {
      _methods = result;
      if (result.success && result.data != null && result.data!.isNotEmpty) {
        _state = _MethodLoadState.success;
      } else if (result.success) {
        _state = _MethodLoadState.noData;
      } else if (result.message != null) {
        // legacy: success == false && message != null -> show server message
        _state = _MethodLoadState.serverError;
      } else {
        // legacy: onFailure -> no internet animation
        _state = _MethodLoadState.noInternet;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          l10n.paymentMethod,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: mainGradient),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMethods,
        color: AppColors.primary,
        child: switch (_state) {
          _MethodLoadState.loading => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 300),
                Center(child: SpinKitThreeBounce(color: AppColors.primary, size: 30)),
              ],
            ),
          _MethodLoadState.noData => ErrorStateWidget(
              type: ErrorStateType.noData,
              noDataMessage: l10n.noPaymentMethods,
              noDataIcon: Icons.account_balance_rounded,
            ),
          _MethodLoadState.serverError => ErrorStateWidget(
              type: ErrorStateType.serverError,
              serverMessage: _methods?.message,
              noDataMessage: l10n.noPaymentMethods,
              noDataIcon: Icons.account_balance_rounded,
            ),
          _MethodLoadState.noInternet => const ErrorStateWidget(type: ErrorStateType.noInternet),
          _MethodLoadState.success => ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _methods!.data!.length,
              itemBuilder: (context, index) {
                final item = _methods!.data![index];
                return _buildMethodCard(item);
              },
            ),
        },
      ),
    );
  }

  Widget _buildMethodCard(PaymentMethodItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.network(
            item.linkLogo,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_balance_rounded, color: AppColors.primary),
          ),
        ),
        title: Text(
          item.namaMetode,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          item.deskripsi,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentInstructionPage(
                method: item,
                totalAmount: widget.totalAmount,
              ),
            ),
          );
        },
      ),
    );
  }
}
