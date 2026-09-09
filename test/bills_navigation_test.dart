import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartmahsiswaflutter/core/storage/session_manager.dart';
import 'package:smartmahsiswaflutter/features/bills/presentation/pages/current_bills_page.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';

void main() {
  testWidgets('tombol history & back pada halaman tagihan berfungsi', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock sesi login agar getUser() tidak null
    SharedPreferences.setMockInitialValues({
      'user_data': jsonEncode({
        'nim': '123456789',
        'kodejen': '01',
        'kodepst': '62601',
      }),
      'is_logged_in': true,
    });
    final session = SessionManager();
    await session.init();

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('id'),
      home: const CurrentBillsPage(),
    ));

    // Biarkan API load berjalan (akan gagal koneksi di env test -> state noInternet)
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));

    // Halaman tagihan tampil
    expect(find.text('Biaya Kuliah'), findsOneWidget);

    // 1. Tap tombol history di app bar
    final historyIcon = find.byIcon(Icons.history_rounded);
    expect(historyIcon, findsOneWidget);
    await tester.tap(historyIcon, warnIfMissed: true);
    await tester.pumpAndSettle();

    // Halaman riwayat pembayaran terbuka
    expect(find.text('Riwayat Pembayaran'), findsOneWidget);

    // 2. Tap tombol back di app bar halaman riwayat
    final backButtons = find.byIcon(Icons.arrow_back_ios_new_rounded);
    expect(backButtons, findsOneWidget);
    await tester.tap(backButtons.last, warnIfMissed: true);
    await tester.pumpAndSettle();

    // Kembali ke halaman tagihan
    expect(find.text('Biaya Kuliah'), findsOneWidget);
  });
}
