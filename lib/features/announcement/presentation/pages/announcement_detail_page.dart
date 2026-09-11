import 'package:flutter/material.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/home_helpers.dart';
import '../../../home/data/models/pengumuman_response.dart';
import 'announcement_image_view_page.dart';

class AnnouncementDetailPage extends StatefulWidget {
  final PengumumanData pengumuman;

  const AnnouncementDetailPage({
    super.key,
    required this.pengumuman,
  });

  @override
  State<AnnouncementDetailPage> createState() => _AnnouncementDetailPageState();
}

class _AnnouncementDetailPageState extends State<AnnouncementDetailPage> {
  late final WebViewController _webViewController;
  bool _isWebViewLoading = true;
  double _webViewHeight = 300.0;

  @override
  void initState() {
    super.initState();
    _initWebViewController();
  }

  void _initWebViewController() {
    final rawHtml = widget.pengumuman.isi;
    final styledHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
  <style>
    html, body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      font-size: 14.5px;
      line-height: 1.65;
      color: #334155;
      margin: 0;
      padding: 0;
      background-color: transparent;
      word-wrap: break-word;
      overflow: hidden;
      height: auto;
    }
    img {
      display: inline-block;
      max-width: 100% !important;
      height: auto !important;
      border-radius: 8px;
      margin: 8px 0;
    }
    iframe {
      max-width: 100% !important;
      border: none;
      border-radius: 8px;
      margin: 8px 0;
    }
    a {
      color: #0056B3;
      text-decoration: underline;
      font-weight: 500;
      word-break: break-all;
    }
    p {
      margin-top: 0;
      margin-bottom: 12px;
    }
    table {
      width: 100% !important;
      border-collapse: collapse;
      margin: 12px 0;
    }
    th, td {
      border: 1px solid #E2E8F0;
      padding: 8px;
      font-size: 13px;
    }
  </style>
</head>
<body>
  $rawHtml
</body>
</html>
''';

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isWebViewLoading = true;
              });
            }
          },
          onPageFinished: (String url) async {
            // Wait briefly for images/fonts to render
            await Future.delayed(const Duration(milliseconds: 300));
            try {
              final result = await _webViewController.runJavaScriptReturningResult(
                'Math.max(document.body.scrollHeight, document.documentElement.scrollHeight)',
              );
              final height = double.tryParse(result.toString());
              if (height != null && height > 0 && mounted) {
                setState(() {
                  _webViewHeight = height + 20;
                  _isWebViewLoading = false;
                });
              } else if (mounted) {
                setState(() {
                  _isWebViewLoading = false;
                });
              }
            } catch (_) {
              if (mounted) {
                setState(() {
                  _isWebViewLoading = false;
                });
              }
            }
          },
          onNavigationRequest: (NavigationRequest request) async {
            // Intercept URL clicks so external links open in device browser
            final uri = Uri.tryParse(request.url);
            if (uri != null &&
                (uri.scheme == 'http' ||
                    uri.scheme == 'https' ||
                    uri.scheme == 'mailto' ||
                    uri.scheme == 'tel')) {
              try {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              } catch (_) {}
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(styledHtml);
  }

  void _openImageViewer(String imageUrl, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnnouncementImageViewPage(
          imageUrl: imageUrl,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final hasImage = widget.pengumuman.linkPicture.trim().isNotEmpty;
    final formattedDate = FormatTanggalIndo.formatDateTime(
      widget.pengumuman.tanggal,
      locale,
    );
    final displayDate = formattedDate.isNotEmpty
        ? formattedDate
        : widget.pengumuman.tanggal;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          color: AppColors.primary,
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    l10n.announcementDetail,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Banner with Zoom Capability
            if (hasImage)
              GestureDetector(
                onTap: () => _openImageViewer(
                  widget.pengumuman.linkPicture,
                  widget.pengumuman.judul,
                ),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 230,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE2E8F0),
                      ),
                      child: Image.network(
                        widget.pengumuman.linkPicture,
                        width: double.infinity,
                        height: 230,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFFE2E8F0),
                          child: const Center(
                            child: Icon(
                              Icons.campaign_rounded,
                              size: 64,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.zoom_out_map_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.viewImage,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Main Content Card
            Container(
              margin: EdgeInsets.only(
                left: 16,
                right: 16,
                top: hasImage ? 16 : 20,
                bottom: 24,
              ),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Badge
                  if (widget.pengumuman.kategori.trim().isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.pengumuman.kategori.trim(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Judul
                  Text(
                    widget.pengumuman.judul,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Divider
                  Container(
                    height: 1,
                    color: const Color(0xFFF1F5F9),
                  ),
                  const SizedBox(height: 12),

                  // Metadata info: Date and Publisher
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          displayDate,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.pengumuman.publisher.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.pengumuman.publisher.trim(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: const Color(0xFFF1F5F9),
                  ),
                  const SizedBox(height: 16),

                  // Webview container for formatted HTML content
                  SizedBox(
                    height: _webViewHeight,
                    child: Stack(
                      children: [
                        WebViewWidget(controller: _webViewController),
                        if (_isWebViewLoading)
                          const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
