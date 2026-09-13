import 'package:flutter/material.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/storage/session_manager.dart';
import '../../../../core/utils/home_helpers.dart';
import '../../../auth/presentation/pages/login_screen.dart';
import '../widgets/language_selector_dialog.dart';
import '../../../keamanan_akun/presentation/pages/security_page.dart';
import '../../../announcement/presentation/pages/announcement_image_view_page.dart';
import '../../../ektm/presentation/pages/ektm_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _sessionManager = SessionManager();

  void _openProfileImageViewer(String imageUrl, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnnouncementImageViewPage(
          imageUrl: imageUrl,
          title: title,
        ),
      ),
    );
  }

  void _handleLogout() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.danger,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.logout,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.logoutConfirm,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final navigator = Navigator.of(context, rootNavigator: true);
                        await _sessionManager.clear();
                        if (!mounted) return;
                        navigator.pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(l10n.ok),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _sessionManager.getUser();
    final l10n = AppLocalizations.of(context)!;

    if (user == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Text(
          l10n.accountSettings,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: CustomScrollView(
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Background overscroll yang menyatu ke AppBar saat layar ditarik ke bawah
                Positioned(
                  top: -600,
                  left: 0,
                  right: 0,
                  height: 600,
                  child: Container(
                    color: AppColors.primary,
                  ),
                ),
                // Background yang warnanya menyatu dengan AppBar,
                // tinggi dari AppBar (top: 0) sampai tengah card, dibuat melengkung seperti di fitur home
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 105,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _buildInfoCard(user, l10n),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildMenuSection(l10n.settings, [
                  _buildMenuItem(
                    Icons.lock_outline,
                    l10n.security,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SecurityPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    Icons.person_outline,
                    l10n.profile,
                    () {},
                  ),
                  _buildMenuItem(
                    Icons.badge_outlined,
                    l10n.ektm,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EktmPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(Icons.language, l10n.language, () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          const LanguageSelectorDialog(),
                    );
                  }),
                  if (!user.emailVerification)
                    _buildMenuItem(
                      Icons.email_outlined,
                      l10n.emailVerif,
                      () {},
                    ),
                ]),

                const SizedBox(height: 24),

                _buildMenuSection(l10n.help, [
                  _buildMenuItem(Icons.help_outline, l10n.help, () {}),
                  _buildMenuItem(Icons.info_outline, l10n.about, () {}),
                  _buildMenuItem(Icons.star_outline, l10n.rateApp, () {}),
                ]),

                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _handleLogout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    elevation: 0,
                  ),
                  child: Text(l10n.logout),
                ),

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(dynamic user, AppLocalizations l10n) {
    final tahunAngkatan = user.angkatan?.toString().substring(0, 4) ?? '2024';
    final nimOnlyNumber = user.nim?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    final profileUrl =
        'https://si-mona.uinsalatiga.ac.id/user_log/view_image?angkatan=$tahunAngkatan&nim=$nimOnlyNumber';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _openProfileImageViewer(
                  profileUrl,
                  user.nama ?? l10n.profile,
                ),
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: Colors.white, // Plain white background
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: ClipOval(
                      child: Image.network(
                        profileUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.nama ?? '-',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mahasiswa ${user.jenjang ?? ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 20),
          _buildInfoItem(l10n.nim, user.nim ?? '-'),
          const SizedBox(height: 16),
          _buildInfoItem(
            l10n.status,
            StatusAkademik.getStatusText(
              user.status,
              user.semester,
              user.semester,
              l10n,
            ),
            isStatus: true,
            statusColor: StatusAkademik.getStatusColor(
              user.status,
              user.semester,
              user.semester,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            l10n.programStudy.toUpperCase(),
            user.programStudi ?? '-',
          ),
          const SizedBox(height: 16),
          _buildInfoItem(l10n.faculty.toUpperCase(), user.fakultas ?? '-'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    String label,
    String value, {
    bool isStatus = false,
    Color? statusColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: isStatus
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor ?? AppColors.primary,
                      // Solid color like home
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      value.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ), // White text like home
                    ),
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  items[i],
                  if (i < items.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 60,
                      endIndent: 16,
                      color: Color(0xFFF1F5F9),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 22,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
      splashColor: AppColors.primary.withValues(alpha: 0.12),
      hoverColor: AppColors.primary.withValues(alpha: 0.06),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
