import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartmahsiswaflutter/core/network/api_service.dart';
import 'package:smartmahsiswaflutter/core/storage/session_manager.dart';
import 'package:smartmahsiswaflutter/features/bills/presentation/pages/current_bills_page.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';

/// Reproduces the on-device bug with REAL API + REAL logged-in user:
/// bills shown -> back / history buttons dead, "Lanjutkan" missing,
/// plus "Cannot hit test a render box with no size".
///
/// Credentials are read from env vars (never committed to the repo):
///   TEST_NIM=... TEST_PASS=... flutter test test/bills_realdata_diagnosis_test.dart
void main() {
  testWidgets('DIAGNOSIS real data: tagihan -> tombol harus bisa diklik', (tester) async {
    final nim = Platform.environment['TEST_NIM'] ?? '';
    final password = Platform.environment['TEST_PASS'] ?? '';
    expect(nim.isNotEmpty && password.isNotEmpty, isTrue,
        reason: 'Set TEST_NIM & TEST_PASS env vars');

    // Capture every framework error (e.g. "Cannot hit test a render box with no size")
    final errors = <FlutterErrorDetails>[];
    FlutterError.onError = errors.add;

    PackageInfo.setMockInitialValues(
      appName: 'smartmahsiswaflutter',
      packageName: 'com.uinsalatiga.smartmhs',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );

    // ---- Real login ----
    final api = ApiService();
    final login = await api.login(
      nim: nim,
      password: password,
      deviceId: 'diag-device-001',
      deviceName: 'flutter-diagnosis',
    );
    // ignore: avoid_print
    print('LOGIN: success=${login.success} resync=${login.resyncrondevice} '
        'msg=${login.message} hasData=${login.data != null}');
    expect(login.success, isTrue, reason: 'Login gagal: ${login.message}');

    // ---- Save session ----
    SharedPreferences.setMockInitialValues({});
    final session = SessionManager();
    await session.init();
    await session.saveUser(login.data!);

    // ---- Render the page ----
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('id'),
      home: const CurrentBillsPage(),
    ));

    // Let Future.microtask + real network call finish
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 15));
    await tester.pump(const Duration(seconds: 2));

    final buildException = tester.takeException();
    // ignore: avoid_print
    print('BUILD EXCEPTION: $buildException');

    // ---- Assertions: bills must be visible WITH bottom bar ----
    final proceedBtn = find.widgetWithText(ElevatedButton, 'Lanjutkan');
    // ignore: avoid_print
    print('ElevatedButton[Lanjutkan]: found=${proceedBtn.evaluate().length} '
        'hitTestable=${proceedBtn.hitTestable().evaluate().length}');
    // ignore: avoid_print
    print('Total Tagihan label: ${find.text('Total Tagihan').evaluate().isNotEmpty}');

    final historyIcon = find.byIcon(Icons.history_rounded);
    // ignore: avoid_print
    print('history icon: found=${historyIcon.evaluate().length} '
        'hitTestable=${historyIcon.hitTestable().evaluate().length}');

    final backIcon = find.byIcon(Icons.arrow_back_ios_new_rounded);
    // ignore: avoid_print
    print('back icon: found=${backIcon.evaluate().length} '
        'hitTestable=${backIcon.hitTestable().evaluate().length}');

    // ---- Tap flow ----
    if (proceedBtn.hitTestable().evaluate().isNotEmpty) {
      await tester.tap(proceedBtn, warnIfMissed: true);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 15));
      // ignore: avoid_print
      print('AFTER TAP LANJUTKAN: exceptions=${tester.takeException()} '
          'MetodePembayaran title=${find.text('Metode Pembayaran').evaluate().isNotEmpty}');
    }

    if (historyIcon.hitTestable().evaluate().isNotEmpty) {
      await tester.tap(historyIcon, warnIfMissed: true);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 15));
      // ignore: avoid_print
      print('AFTER TAP HISTORY: exceptions=${tester.takeException()} '
          'RiwayatPembayaran title=${find.text('Riwayat Pembayaran').evaluate().isNotEmpty}');
    }

    // ---- Dump captured framework errors with stack traces ----
    // ignore: avoid_print
    print('=== CAPTURED FRAMEWORK ERRORS: ${errors.length} ===');
    for (final e in errors) {
      // ignore: avoid_print
      print('--- ERROR ---\n${e.toString()}');
    }
  });
}
