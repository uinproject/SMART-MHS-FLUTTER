import 'package:flutter/material.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

class MainMenuGrid extends StatefulWidget {
  const MainMenuGrid({super.key});

  @override
  State<MainMenuGrid> createState() => _MainMenuGridState();
}

class _MainMenuGridState extends State<MainMenuGrid> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    final List<Map<String, dynamic>> allMenus = [
      {'icon': Icons.calendar_today, 'label': 'Jadwal'},
      {'icon': Icons.receipt_long, 'label': 'Tagihan'},
      {'icon': Icons.qr_code_scanner, 'label': 'Presensi'},
      {'icon': Icons.history, 'label': 'Kehadiran'},
      {'icon': Icons.rate_review, 'label': 'EDOM'},
      {'icon': Icons.insights, 'label': 'Riwayat IP'},
      {'icon': Icons.local_offer, 'label': 'Penawaran'},
      {'icon': Icons.description, 'label': 'KRS'},
      {'icon': Icons.school, 'label': 'KHS'},
    ];

    final visibleMenus = _showAll ? allMenus : allMenus.take(8).toList();

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
              InkWell(
                onTap: () => setState(() => _showAll = !_showAll),
                child: Text(
                  _showAll ? l10n.cancel : l10n.showAll,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
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
              onTap: () {},
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
