import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class AppWebViewHelper {
  AppWebViewHelper._();

  /// Standard Chrome User Agent for Android (Chromium Reduced User-Agent format).
  static const String androidChromeUserAgent =
      'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Mobile Safari/537.36';

  /// Standard Safari User Agent for iOS.
  static const String iOSSafariUserAgent =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1';

  static String get defaultUserAgent {
    if (!kIsWeb && Platform.isIOS) {
      return iOSSafariUserAgent;
    }
    return androidChromeUserAgent;
  }

  /// Configures platform-specific settings for Cloudflare / Turnstile challenge support.
  /// This enables third-party cookies (needed for challenges.cloudflare.com iframe),
  /// removes embedded webview indicators (; wv, Version/4.0) from User-Agent,
  /// and disables gesture requirements for media/verification.
  static Future<void> configureForCloudflare(WebViewController controller) async {
    try {
      if (controller.platform is AndroidWebViewController) {
        final androidController = controller.platform as AndroidWebViewController;

        // 1. Enable third-party cookies (critical for Cloudflare Turnstile iframes)
        final cookieManager = WebViewCookieManager().platform;
        if (cookieManager is AndroidWebViewCookieManager) {
          await cookieManager.setAcceptThirdPartyCookies(androidController, true);
        }

        // 2. Media playback without user gesture
        await androidController.setMediaPlaybackRequiresUserGesture(false);

        // 3. User agent: clean system UA by removing WebView markers (; wv, Version/4.0)
        try {
          final systemUa = await androidController.getUserAgent();
          if (systemUa != null && systemUa.isNotEmpty) {
            final cleanedUa = systemUa
                .replaceAll('; wv', '')
                .replaceAll(RegExp(r'Version\/4\.0\s?'), '');
            await controller.setUserAgent(cleanedUa);
          } else {
            await controller.setUserAgent(androidChromeUserAgent);
          }
        } catch (_) {
          await controller.setUserAgent(androidChromeUserAgent);
        }
      } else if (!kIsWeb && Platform.isIOS) {
        await controller.setUserAgent(iOSSafariUserAgent);
      } else {
        await controller.setUserAgent(defaultUserAgent);
      }
    } catch (e) {
      debugPrint('AppWebViewHelper: error configuring for Cloudflare: $e');
    }
  }

  /// Injects anti-bot detection mitigation script into the WebView.
  static Future<void> injectAntiBotScripts(WebViewController controller) async {
    try {
      await controller.runJavaScript('''
        try {
          Object.defineProperty(navigator, 'webdriver', {
            get: () => undefined,
          });

          if (!window.chrome) {
            window.chrome = {
              runtime: {},
              loadTimes: function() {},
              csi: function() {},
              app: {}
            };
          }
        } catch (e) {}
      ''');
    } catch (_) {}
  }

  /// Determines if an error is a non-fatal / aborted request during redirects.
  static bool isIgnorableError(WebResourceError error) {
    if (error.errorCode == -3 || // net::ERR_ABORTED
        error.errorCode == -9 || // net::ERR_UNEXPECTED
        error.errorCode == -1 || // generic cancelled
        error.description.contains('ERR_ABORTED') ||
        error.description.contains('ERR_BLOCKED_BY_CLIENT') ||
        error.description.contains('net::ERR_CACHE_MISS')) {
      return true;
    }
    return false;
  }
}
