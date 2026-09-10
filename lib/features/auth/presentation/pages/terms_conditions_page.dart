import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/storage/session_manager.dart';
import '../../../../core/utils/app_constants.dart';
import 'login_screen.dart';

class TermsConditionsPage extends StatefulWidget {
  const TermsConditionsPage({super.key});

  @override
  State<TermsConditionsPage> createState() => _TermsConditionsPageState();
}

class _TermsConditionsPageState extends State<TermsConditionsPage> {
  late final WebViewController _controller;

  bool _isAccepted = false;
  bool _isLoading = true;
  bool _hasError = false;

  static const String _termsUrl =
      'https://smart.uinsalatiga.ac.id/smart/sk_smart_mhs_mobile_vsplashscreen';

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    final controller = WebViewController();

    controller
      // JavaScript diperlukan oleh sebagian halaman modern.
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // User agent standar. Jangan memaksa versi OS/browser tertentu.
      ..setUserAgent(
        'Mozilla/5.0 (Mobile) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36',
      )
      // Konfigurasi navigasi.
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (!mounted) return;

            setState(() {
              _isLoading = true;
              _hasError = false;
            });

            debugPrint('WebView started: $url');
          },

          onPageFinished: (String url) {
            if (!mounted) return;

            setState(() {
              _isLoading = false;
            });

            debugPrint('WebView finished: $url');
          },

          onWebResourceError: (WebResourceError error) {
            debugPrint(
              'WebView error: '
              '${error.description} '
              '(code: ${error.errorCode}) '
              'URL: ${error.url}',
            );

            // Jangan langsung menampilkan error untuk semua resource.
            // Beberapa resource seperti gambar/JS dapat gagal tetapi
            // halaman utama tetap bisa ditampilkan.
            if (error.isForMainFrame == true) {
              if (!mounted) return;

              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },

          onNavigationRequest: (NavigationRequest request) {
            debugPrint('WebView navigation: ${request.url}');

            return NavigationDecision.navigate;
          },
        ),
      )
      // Load halaman setelah seluruh konfigurasi selesai.
      ..loadRequest(Uri.parse(_termsUrl));

    _controller = controller;
  }

  Future<void> _reloadPage() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    await _controller.reload();
  }

  Future<void> _acceptTerms() async {
    if (!_isAccepted || _isLoading) {
      return;
    }

    final sessionManager = SessionManager();

    await sessionManager.setSkAccepted(true);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _cancel() {
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: Text(
          l10n.termsConditions,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),

      body: Column(
        children: [
          // ============================================================
          // WEBVIEW
          // ============================================================
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: WebViewWidget(controller: _controller)),

                // Loading
                if (_isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.white,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.pleaseWait,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Error halaman utama
                if (_hasError && !_isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.wifi_off_rounded,
                              size: 56,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.pageLoadFailed,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.checkInternetConnection,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _reloadPage,
                              icon: const Icon(Icons.refresh),
                              label: Text(l10n.tryAgain),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(140, 46),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ============================================================
          // BOTTOM ACTION AREA
          // ============================================================
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ======================================================
                // CHECKBOX
                // ======================================================
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _isAccepted,

                        onChanged: _isLoading
                            ? null
                            : (bool? value) {
                                if (!mounted) return;

                                setState(() {
                                  _isAccepted = value ?? false;
                                });
                              },

                        activeColor: AppColors.primary,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _isAccepted = !_isAccepted;
                                });
                              },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '${l10n.termsContent} ${AppConstants.company}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ======================================================
                // BUTTONS
                // ======================================================
                Row(
                  children: [
                    // CANCEL
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _cancel,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(l10n.cancel),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // AGREE
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isAccepted && !_isLoading
                            ? _acceptTerms
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.primary
                              .withValues(alpha: 0.35),
                          disabledForegroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          l10n.agreeAndContinue,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
