import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartmahsiswaflutter/core/storage/session_manager.dart';
import 'package:smartmahsiswaflutter/features/krs/presentation/pages/sub_menu_krs_page.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';

void main() {
  testWidgets('navigasi sub menu KRS: Lihat KRS & Input KRS berfungsi', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock sesi login agar getUser() tidak null
    SharedPreferences.setMockInitialValues({
      'user_data': jsonEncode({
        'nim': '123456789',
        'kodejen': '01',
        'kodepst': '62601',
        'semester': 5,
      }),
      'is_logged_in': true,
    });
    final session = SessionManager();
    await session.init();

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('id'),
      home: const SubMenuKrsPage(),
    ));

    // Halaman sub menu tampil
    expect(find.text('Sub Menu KRS'), findsOneWidget);
    expect(find.text('Kartu Rencana Studi'), findsOneWidget);
    expect(find.text('Input KRS'), findsOneWidget);

    // 1. Tap kartu Lihat KRS
    await tester.tap(find.text('Kartu Rencana Studi'), warnIfMissed: true);
    await tester.pumpAndSettle();

    // API load berjalan (gagal koneksi di env test -> state noInternet/error)
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));

    // Halaman Lihat KRS terbuka (title AppBar)
    expect(find.text('Kartu Rencana Studi'), findsWidgets);

    // Back ke sub menu
    final backButtons = find.byIcon(Icons.arrow_back_ios_new_rounded);
    expect(backButtons, findsOneWidget);
    await tester.tap(backButtons.last, warnIfMissed: true);
    await tester.pumpAndSettle();

    expect(find.text('Sub Menu KRS'), findsOneWidget);

    // 2. Tap kartu Input KRS
    await tester.tap(find.text('Input KRS'), warnIfMissed: true);
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));

    // Halaman Input KRS terbuka
    expect(find.text('Input KRS'), findsWidgets);
  });
}
