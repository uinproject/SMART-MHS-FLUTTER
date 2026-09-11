import 'package:flutter/material.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../schedule/presentation/pages/schedule_page.dart';
import '../../../bills/presentation/pages/current_bills_page.dart';
import '../../../offers/presentation/pages/sub_menu_offers_page.dart';
import '../../../krs/presentation/pages/sub_menu_krs_page.dart';
import '../../../edom/presentation/pages/edom_semesters_page.dart';
import '../../../khs/presentation/pages/khs_page.dart';
import '../../../academic_history/presentation/pages/academic_history_page.dart';
import '../../../presence/presentation/pages/presence_scanner_page.dart';
import '../../../attendance/presentation/pages/attendance_courses_page.dart';
import '../../../qibla/presentation/pages/qibla_page.dart';
import '../../../prayer_time/presentation/pages/prayer_time_page.dart';

class MainMenuGrid extends StatefulWidget {
  const MainMenuGrid({super.key});

  @override
  State<MainMenuGrid> createState() => _MainMenuGridState();
}

class _MainMenuGridState extends State<MainMenuGrid> {
  /// Collapsed grid shows 2 rows x 4 columns; "Lihat Lebih" reveals the rest.
  static const int _collapsedItemCount = 8;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Payment History is intentionally NOT a separate menu entry anymore:
    // it is now reachable from the Bills page app bar (same as user request,
    // replacing the legacy tab layout).
    final List<Map<String, dynamic>> allMenus = [
      {'icon': Icons.calendar_today_rounded, 'label': l10n.schedule},
      {'icon': Icons.receipt_long_rounded, 'label': l10n.bills},
      {'icon': Icons.qr_code_scanner_rounded, 'label': l10n.presence},
      {'icon': Icons.check_circle_outline_rounded, 'label': l10n.attendance},
      {'icon': Icons.rate_review_rounded, 'label': l10n.edom},
      {'icon': Icons.insights_rounded, 'label': l10n.academicHistory},
      {'icon': Icons.local_offer_rounded, 'label': l10n.offers},
      {'icon': Icons.description_rounded, 'label': l10n.krs},
      {'icon': Icons.school_rounded, 'label': l10n.khs},
      {'icon': Icons.explore_rounded, 'label': l10n.qiblaDirection},
      {'icon': Icons.access_time_filled_rounded, 'label': l10n.prayerSchedule},
    ];

    final visibleMenus = _showAll
        ? allMenus
        : allMenus.take(_collapsedItemCount).toList();
    final bool hasMore = allMenus.length > _collapsedItemCount;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.mainMenu,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.82,
          ),
          itemCount: visibleMenus.length,
          itemBuilder: (context, index) {
            final menu = visibleMenus[index];
            return _buildMenuItem(
              icon: menu['icon'],
              label: menu['label'],
              onTap: () {
                if (menu['label'] == l10n.schedule) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SchedulePage(),
                    ),
                  );
                } else if (menu['label'] == l10n.bills) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CurrentBillsPage(),
                    ),
                  );
                } else if (menu['label'] == l10n.offers) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubMenuOffersPage(),
                    ),
                  );
                } else if (menu['label'] == l10n.krs) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubMenuKrsPage(),
                    ),
                  );
                } else if (menu['label'] == l10n.edom) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EdomSemestersPage(),
                    ),
                  );
                } else if (menu['label'] == l10n.khs) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const KhsPage()),
                  );
                } else if (menu['label'] == l10n.academicHistory) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AcademicHistoryPage(),
                    ),
                  );
                } else if (menu['label'] == l10n.presence) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PresenceScannerPage(),
                    ),
                  );
                } else if (menu['label'] == l10n.attendance) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AttendanceCoursesPage(),
                    ),
                  );
                } else if (menu['label'] == l10n.qiblaDirection) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QiblaPage(),
                    ),
                  );
                } else if (menu['label'] == l10n.prayerSchedule) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrayerTimePage(),
                    ),
                  );
                }
              },
            );
          },
        ),
        // "Lihat Lebih" / "Tutup" toggle (only when there are hidden items)
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextButton.icon(
              onPressed: () => setState(() => _showAll = !_showAll),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: Icon(
                _showAll
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              label: Text(
                _showAll ? l10n.showLess : l10n.showMore,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: const Color(0xFFEDF2F7),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
