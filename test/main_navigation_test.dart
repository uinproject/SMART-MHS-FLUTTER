import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartmahsiswaflutter/core/storage/session_manager.dart';
import 'package:smartmahsiswaflutter/features/home/presentation/pages/main_page.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SessionManager().init();
  });

  group('MainPage Back Navigation Tests', () {
    testWidgets('Pressing back when not on Home tab switches to Home tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MainPage(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Initial tab is Home (index 0)
      final bottomNavFinder = find.byType(BottomNavigationBar);
      expect(bottomNavFinder, findsOneWidget);
      BottomNavigationBar nav = tester.widget(bottomNavFinder);
      expect(nav.currentIndex, 0);

      // Tap on News tab (index 1)
      await tester.tap(find.byIcon(Icons.newspaper_outlined));
      await tester.pump(const Duration(milliseconds: 100));

      nav = tester.widget(bottomNavFinder);
      expect(nav.currentIndex, 1);

      // Simulate back press via handlePopRoute
      final dynamic widgetsBinding = tester.binding;
      await widgetsBinding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 100));

      // Should now be back on Home tab (index 0)
      nav = tester.widget(bottomNavFinder);
      expect(nav.currentIndex, 0);
    });

    testWidgets('Pressing back on Prayer Time tab (index 2) switches to Home tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MainPage(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      final bottomNavFinder = find.byType(BottomNavigationBar);

      // Tap on Prayer Time tab (index 2)
      await tester.tap(find.byIcon(Icons.mosque_outlined));
      await tester.pump(const Duration(milliseconds: 100));

      BottomNavigationBar nav = tester.widget(bottomNavFinder);
      expect(nav.currentIndex, 2);

      // Simulate back press
      final dynamic widgetsBinding = tester.binding;
      await widgetsBinding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 100));

      // Should be back on Home tab (index 0)
      nav = tester.widget(bottomNavFinder);
      expect(nav.currentIndex, 0);
    });

    testWidgets('Pressing back on Account tab (index 3) switches to Home tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MainPage(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      final bottomNavFinder = find.byType(BottomNavigationBar);

      // Tap on Account tab (index 3)
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pump(const Duration(milliseconds: 100));

      BottomNavigationBar nav = tester.widget(bottomNavFinder);
      expect(nav.currentIndex, 3);

      // Simulate back press
      final dynamic widgetsBinding = tester.binding;
      await widgetsBinding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 100));

      // Should be back on Home tab (index 0)
      nav = tester.widget(bottomNavFinder);
      expect(nav.currentIndex, 0);
    });
  });
}
