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
/// - pull-to-refresh (legacy SwipeRefreshLayout). Uniform error handling:
/// an API ANSWER with status+message is informational (regular icon),
/// API-level failures (network / HTTP error) show the error icon.
enum _MethodLoadState {
  loading,
  success,
  noData,
  serverMessage,
  serverError,
  noInternet,
}

class SelectPaymentMethodPage extends StatefulWidget {
  final int totalAmount;
  const SelectPaymentMethodPage({super.key, required this.totalAmount});

  @override
  State<SelectPaymentMethodPage> createState() =>
      _SelectPaymentMethodPageState();
}

class _SelectPaymentMethodPageState extends State<SelectPaymentMethodPage> {
  final _apiService = ApiService();
  final _sessionManager = SessionManager();

  PaymentMethodResponse? _methods;
  _MethodLoadState _state = _MethodLoadState.loading;

  /// Failure detail for the API-level error states ("Error 500" / general).
  String? _errorMessage;

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
      if (mounted) {
        setState(() {
          _state = _MethodLoadState.serverError;
          _errorMessage = AppLocalizations.of(context)!.sessionExpired;
        });
      }
      return;
    }

    try {
      // NIM is filtered to digits-only inside the service (same as legacy).
      // Legacy sends the language field for this endpoint (unlike tagihan/rekap).
      final result = await _apiService.getPaymentMethods(
        nim: user.nim ?? '',

      );

      if (!mounted) return;
      setState(() {
        _methods = result;
        if (result.success && result.data != null && result.data!.isNotEmpty) {
          _state = _MethodLoadState.success;
        } else if (result.success) {
          _state = _MethodLoadState.noData;
        } else if (result.message != null && result.message!.isNotEmpty) {
          // The API ANSWERED with a status + message — informational, shown
          // with the regular (bank) icon, not the error icon.
          _state = _MethodLoadState.serverMessage;
        } else {
          // Answered without a message — connection-level failure.
          _state = _MethodLoadState.noInternet;
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
            ? _MethodLoadState.noInternet
            : _MethodLoadState.serverError;
      });
    }
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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.paymentMethod,
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
      body: RefreshIndicator(
        onRefresh: _loadMethods,
        color: AppColors.primary,
        child: switch (_state) {
          _MethodLoadState.loading => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 300),
              Center(
                child: SpinKitThreeBounce(color: AppColors.primary, size: 30),
              ),
            ],
          ),
          _MethodLoadState.noData => ErrorStateWidget(
            type: ErrorStateType.noData,
            noDataMessage: l10n.noPaymentMethods,
            noDataIcon: Icons.account_balance_rounded,
          ),
          _MethodLoadState.serverMessage => ErrorStateWidget(
            type: ErrorStateType.noData,
            // API answered with status+message → old (informational) icon.
            noDataMessage: _methods?.message,
            noDataIcon: Icons.account_balance_rounded,
          ),
          _MethodLoadState.serverError => ErrorStateWidget(
            type: ErrorStateType.serverError,
            serverMessage: _errorMessage,
          ),
          _MethodLoadState.noInternet => const ErrorStateWidget(
            type: ErrorStateType.noInternet,
          ),
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
    final isRtl = Directionality.of(context) == TextDirection.rtl;

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
        child: InkWell(
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
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 42,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.iconBackground),
                  ),
                  child: Image.network(
                    item.linkLogo,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.account_balance_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.namaMetode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (item.deskripsi.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          item.deskripsi,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Transform.flip(
                  flipX: isRtl,
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
