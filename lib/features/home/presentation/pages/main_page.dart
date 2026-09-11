import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'home_page.dart';
import '../../../account/presentation/pages/account_page.dart';
import '../../../news/presentation/pages/news_page.dart';
import '../../../prayer_time/presentation/pages/prayer_time_page.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const NewsPage(),
    const PrayerTimePage(),
    const AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: l10n.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.newspaper_outlined),
            activeIcon: const Icon(Icons.newspaper),
            label: l10n.news,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.mosque_outlined),
            activeIcon: const Icon(Icons.mosque_rounded),
            label: l10n.prayerShortLabel,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: l10n.account,
          ),
        ],
      ),
    );
  }
}
