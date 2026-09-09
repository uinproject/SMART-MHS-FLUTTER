import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_notifications.dart';
import '../../data/models/payment_method_response.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Mirrors the legacy `DetailMetodePembayaran` business logic:
/// - Card 1: Tagihan / Biaya Admin / Total Bayar (= tagihan + biaya adm)
/// - Card 2: logo + "{nama_metode} ({Verifikasi Otomatis})", Nomor Pembayaran
///   with copy-to-clipboard, and the method `deskripsi`
/// - Card 3: Petunjuk Pembayaran (tata_cara HTML rendered in a WebView)
class PaymentInstructionPage extends StatefulWidget {
  final PaymentMethodItem method;
  final int totalAmount;
  const PaymentInstructionPage({
    super.key,
    required this.method,
    required this.totalAmount,
  });

  @override
  State<PaymentInstructionPage> createState() => _PaymentInstructionPageState();
}

class _PaymentInstructionPageState extends State<PaymentInstructionPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..loadHtmlString(_wrapHtml(widget.method.tataCara));
  }

  String _wrapHtml(String content) {
    return """
    <!DOCTYPE html>
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { 
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
          font-size: 14px;
          line-height: 1.6;
          color: #334155;
          margin: 0;
          padding: 16px;
        }
        b, strong { color: #003D82; }
      </style>
    </head>
    <body>
      $content
    </body>
    </html>
    """;
  }

  void _copyPaymentNumber(String value) {
    Clipboard.setData(ClipboardData(text: value));
    final l10n = AppLocalizations.of(context)!;
    AppNotifications.show(
      context,
      l10n.paymentNumberCopied,
      type: AppNotificationType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final totalPay = widget.totalAmount + widget.method.biayaAdm;

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
          l10n.paymentInstructions,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: mainGradient),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card 1 — amount summary (legacy "layouttotal")
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    padding: const EdgeInsets.all(24),
                    decoration: _cardDecoration(),
                    child: Column(
                      children: [
                        _buildSummaryRow(l10n.billLabel, currencyFormat.format(widget.totalAmount)),
                        _buildSummaryRow(l10n.adminFee, currencyFormat.format(widget.method.biayaAdm)),
                        const Divider(height: 24),
                        _buildSummaryRow(l10n.totalPay, currencyFormat.format(totalPay), isTotal: true),
                      ],
                    ),
                  ),

                  // Card 2 — bank / payment channel (legacy "layoutbank")
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    padding: const EdgeInsets.all(24),
                    decoration: _cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.iconBackground),
                              ),
                              child: Image.network(
                                widget.method.linkLogo,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_balance_rounded),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                '${widget.method.namaMetode} (${l10n.automaticVerification})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 28),
                        Text(
                          l10n.paymentNumber,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.method.norek,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => _copyPaymentNumber(widget.method.norek),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.copy_rounded, size: 14, color: AppColors.secondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.copy,
                                      style: const TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (widget.method.deskripsi.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            widget.method.deskripsi,
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Card 3 — payment instructions (legacy WebView with tata_cara HTML)
                  Container(
                    width: double.infinity,
                    height: 340,
                    margin: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    padding: const EdgeInsets.all(24),
                    decoration: _cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              l10n.paymentInstructions,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: WebViewWidget(controller: _controller),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: isTotal ? 14 : 13,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isTotal ? 18 : 14,
              color: isTotal ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
