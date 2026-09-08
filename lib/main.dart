import 'package:flutter/material.dart';
import 'core/storage/session_manager.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/splash_screen.dart';

import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  final sessionManager = SessionManager();
  await sessionManager.init();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('id');

  @override
  void initState() {
    super.initState();
    _loadSavedLocale();
  }

  void _loadSavedLocale() {
    final session = SessionManager();
    final savedCode = session.getLocale();
    setState(() {
      _locale = Locale(savedCode);
    });
  }

  void setLocale(Locale value) {
    setState(() {
      _locale = value;
    });
    SessionManager().setLocale(value.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart MHS',
      debugShowCheckedModeBanner: false,
      theme: _locale.languageCode == 'ar' 
        ? AppTheme.lightTheme.copyWith(
            textTheme: GoogleFonts.amiriTextTheme(AppTheme.lightTheme.textTheme),
          )
        : AppTheme.lightTheme,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.ltr, // Force LTR even for Arabic
          child: child!,
        );
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id'),
        Locale('en'),
        Locale('ar'),
      ],
      locale: _locale,
      home: const SplashScreen(),
    );
  }
}
