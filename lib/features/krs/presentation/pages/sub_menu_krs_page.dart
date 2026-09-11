import 'package:flutter/material.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import 'view_krs_page.dart';
import 'input_krs_page.dart';

/// Mirrors the legacy `SubMenuKrsActivity`: a 2-option sub-menu
/// (Kartu Rencana Studi / Input KRS) reached from the home grid "KRS".
class SubMenuKrsPage extends StatelessWidget {
  const SubMenuKrsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.krsSubmenuTitle,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildMenuCard(
            context: context,
            icon: Icons.menu_book_rounded,
            title: l10n.viewKrsTitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ViewKrsPage()),
            ),
          ),
          const SizedBox(height: 16),
          _buildMenuCard(
            context: context,
            icon: Icons.post_add_rounded,
            title: l10n.inputKrsTitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const InputKrsPage()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
