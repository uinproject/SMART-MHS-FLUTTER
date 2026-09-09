import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/metode_pembayaran_response.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentInstructionPage extends StatefulWidget {
  final MetodePembayaranData method;
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
      ..setJavaScriptMode(GestureDetector.allow() == null ? JavaScriptMode.unrestricted : JavaScriptMode.disabled)
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
          padding: 0;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final totalPay = widget.totalAmount + (int.tryParse(widget.method.biayaAdm) ?? 0);

    const mainGradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [Color(0xFF003D82), Color(0xFF0056B3)],
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        pinned: true,
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Summary
            Container(
              padding: const EdgeInsets.all(24),
              color: const Color(0xFFF8FAFC),
              child: Column(
                children: [
                  Row(
                    children: [
                      Image.network(
                        widget.method.linkLogo,
                        width: 60,
                        height: 40,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_balance_rounded),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.method.namaMetode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Text('Verifikasi Otomatis', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  _buildSummaryRow('No. Pembayaran / VA', widget.method.norek, isPrimary: true, canCopy: true),
                  _buildSummaryRow('Total Tagihan', currencyFormat.format(widget.totalAmount)),
                  _buildSummaryRow('Biaya Admin', currencyFormat.format(int.tryParse(widget.method.biayaAdm) ?? 0)),
                  const Divider(height: 32),
                  _buildSummaryRow('Total Bayar', currencyFormat.format(totalPay), isTotal: true),
                ],
              ),
            ),
            
            // Instructions
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tata Cara Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 500, // Fixed height or dynamic based on content
                    child: WebViewWidget(controller: _controller),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isPrimary = false, bool isTotal = false, bool canCopy = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: isTotal ? 14 : 13)),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isTotal ? 18 : (isPrimary ? 16 : 14),
                  color: isTotal || isPrimary ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              if (canCopy) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nomor pembayaran berhasil disalin')),
                    );
                  },
                  child: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
