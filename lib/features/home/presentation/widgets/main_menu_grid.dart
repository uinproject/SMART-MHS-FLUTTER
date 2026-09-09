import 'package:flutter/material.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../schedule/presentation/pages/schedule_page.dart';
import '../../../bills/presentation/pages/current_bills_page.dart';
import '../../../offers/presentation/pages/sub_menu_offers_page.dart';

class MainMenuGrid extends StatefulWidget {
  const MainMenuGrid({super.key});

  @override
  State<MainMenuGrid> createState() => _MainMenuGridState();
}

class _MainMenuGridState extends State<MainMenuGrid> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Payment History is intentionally NOT a separate menu entry anymore:
    // it is now reachable from the Bills page app bar (same as user request,
    // replacing the legacy tab layout). Keep exactly 8 items (no show-all).
    final List<Map<String, dynamic>> allMenus = [
      {'icon': Icons.calendar_today_rounded, 'label': l10n.schedule},
      {'icon': Icons.receipt_long_rounded, 'label': l10n.bills},
      {'icon': Icons.qr_code_scanner_rounded, 'label': l10n.presence},
      {'icon': Icons.rate_review_rounded, 'label': l10n.edom},
      {'icon': Icons.insights_rounded, 'label': l10n.ipHistory},
      {'icon': Icons.local_offer_rounded, 'label': l10n.offers},
      {'icon': Icons.description_rounded, 'label': l10n.krs},
      {'icon': Icons.school_rounded, 'label': l10n.khs},
    ];

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
          itemCount: allMenus.length,
          itemBuilder: (context, index) {
            final menu = allMenus[index];
            return _buildMenuItem(
              icon: menu['icon'],
              label: menu['label'],
              onTap: () {
                if (menu['label'] == l10n.schedule) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SchedulePage()),
                  );
                } else if (menu['label'] == l10n.bills) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CurrentBillsPage()),
                  );
                } else if (menu['label'] == l10n.offers) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SubMenuOffersPage()),
                  );
                }
              },
            );
          },
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
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 24,
              ),
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
