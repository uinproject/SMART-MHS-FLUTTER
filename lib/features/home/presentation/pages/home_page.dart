import 'package:flutter/material.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/session_manager.dart';
import '../../../../core/utils/home_helpers.dart';
import '../../../auth/data/models/login_data.dart';
import '../widgets/home_header.dart';
import '../widgets/main_menu_grid.dart';
import '../widgets/announcement_carousel.dart';
import '../../data/models/pengumuman_response.dart';
import 'package:smartmahsiswaflutter/features/auth/presentation/pages/login_screen.dart';
import 'package:smartmahsiswaflutter/features/edom/presentation/pages/edom_semesters_page.dart';
import '../../../../core/utils/device_utils.dart';
import '../../../../core/widgets/action_required_dialog.dart';
import '../../../helpdesk/presentation/pages/cs_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  final _apiService = ApiService();
  final _sessionManager = SessionManager();

  PengumumanResponse? _pengumuman;
  bool _isLoading = true;

  /// Legacy `showeval` flag: the EDOM reminder dialog is shown at most
  /// ONCE per page lifetime (pull-to-refresh / revisits must not spam it).
  bool _evalDialogShown = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData(isRefresh: false);
  }

  Future<void> _loadData({bool isRefresh = false}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final user = _sessionManager.getUser();
      if (user != null) {
        final bool shouldRefresh = isRefresh || !_sessionManager.isJustLoggedIn;
        if (shouldRefresh) {
          final deviceId = await DeviceUtils.getDeviceId();

          final updatedUser = await _apiService.refreshSession(
            nim: user.nim ?? '',
            deviceId: deviceId,
          );

          if (updatedUser != null) {
            await _sessionManager.saveUser(updatedUser);
          }
        }
        _sessionManager.isJustLoggedIn = false;

        final pengumuman = await _apiService.getPengumuman(
          nim: user.nim,
          kodeJen: user.kodeJen,
          kodeFak: user.kodeFakultas,
          kodePst: user.kodePst,
        );

        if (mounted) {
          setState(() {
            _pengumuman = pengumuman;
            _isLoading = false;
          });

          // EDOM reminder (legacy HomeFragment: `!cekeval && !showeval` on
          // the API response) — informational dialog, cancelable.
          // Null-safe: response can be null and `cekeval` can be null
          // (server omits / sends null) — only an explicit `false` shows
          // the dialog.
          if (pengumuman?.cekEval == false && !_evalDialogShown) {
            _evalDialogShown = true;
            _showEvalReminderDialog();
          }
        }
      }
    } on ForceLogoutException catch (_) {
      await _sessionManager.clear();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        // sessionExpired: true -> login page shows "session expired"
        MaterialPageRoute(
          builder: (context) => const LoginScreen(sessionExpired: true),
        ),
        (route) => false,
      );
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Legacy `HomeFragment.dialog_show_eval_notif` (two-button variant):
  /// informational reminder that the lecturer evaluation is incomplete —
  /// cancelable via the barrier AND a cancel button (unlike the blocking
  /// one-button dialog in KRS/offers/KHS). The action PUSHES the EDOM flow
  /// so Home stays on the stack (legacy: startActivity without finish).
  void _showEvalReminderDialog() {
    final l10n = AppLocalizations.of(context)!;
    showActionRequiredDialog(
      context: context,
      message: l10n.evalNotCompletedMessage,
      actionLabel: l10n.completeLecturerEval,
      cancelLabel: l10n.cancel,
      dismissible: true,
      icon: Icons.assignment_turned_in_rounded,
      iconColor: AppColors.primary,
      iconBackground: AppColors.primary,
      onAction: () {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EdomSemestersPage()),
        );
      },
    );
  }

  static const Color headerColor = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = _sessionManager.getUser();
    final l10n = AppLocalizations.of(context)!;

    if (user == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: headerColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            _buildAvatar(user),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    SalamWaktu.getSalam(l10n),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTitleCase(user.nama),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            _buildNotificationBell(context, l10n),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCustomerService(context),
        backgroundColor: const Color(0xFFF59E0B),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        tooltip: 'Customer Service',
        child: const Icon(
          Icons.support_agent_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      body: RefreshIndicator(
        color: headerColor,
        backgroundColor: Colors.white,
        onRefresh: () => _loadData(isRefresh: true),
        child: CustomScrollView(
          clipBehavior: Clip.none,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Background overscroll yang menyatu ke AppBar saat layar ditarik ke bawah (swipe refresh)
                  Positioned(
                    top: -600,
                    left: 0,
                    right: 0,
                    height: 600,
                    child: Container(
                      color: headerColor,
                    ),
                  ),
                  // Background yang warnanya menyatu dengan AppBar,
                  // tinggi dari AppBar (top: 0) sampai tengah-tengah card (~105px), dibuat melengkung
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 105,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: headerColor,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(28),
                          bottomRight: Radius.circular(28),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: HomeHeader.buildAcademicCard(user, l10n),
                  ),
                ],
              ),
            ),
            if (_pengumuman?.pesanPenting != null &&
                _pengumuman!.pesanPenting!.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildSmallImportantMessage(
                  _pengumuman!.pesanPenting!,
                  l10n,
                ),
              ),
            const SliverToBoxAdapter(child: MainMenuGrid()),
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: AnnouncementCarousel(
                  announcements: _pengumuman?.data ?? [],
                ),
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
    );
  }

  /// Capitalize each word so only the first letter is uppercase
  String _formatTitleCase(String? text) {
    if (text == null || text.trim().isEmpty) return 'Mahasiswa';
    return text.trim().split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return '';
      if (word.length == 1) return word.toUpperCase();
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Avatar profile picture in AppBar
  Widget _buildAvatar(LoginData user) {
    final tahunAngkatan = user.angkatan?.toString().substring(0, 4) ?? '2024';
    final nimOnlyNumber = user.nim?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    final profileUrl =
        'https://si-mona.uinsalatiga.ac.id/user_log/view_image?angkatan=$tahunAngkatan&nim=$nimOnlyNumber';

    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: SizedBox(
        width: 38,
        height: 38,
        child: ClipOval(
          child: Image.network(
            profileUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.white,
              child:
                  const Icon(Icons.person, color: AppColors.primary, size: 22),
            ),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(color: Colors.white24);
            },
          ),
        ),
      ),
    );
  }

  /// Notification bell button in AppBar with unread badge if important message exists
  Widget _buildNotificationBell(BuildContext context, AppLocalizations l10n) {
    final hasNotification = _pengumuman?.pesanPenting != null &&
        _pengumuman!.pesanPenting!.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () => _showNotificationModal(context, l10n),
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
            size: 26,
          ),
          splashRadius: 24,
        ),
        if (hasNotification)
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  /// Modal bottom sheet for notifications
  void _showNotificationModal(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded,
                        color: AppColors.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      l10n.notifications,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_pengumuman?.pesanPenting != null &&
                _pengumuman!.pesanPenting!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFF003D82), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.checkKrs.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF003D82),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _pengumuman!.pesanPenting!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.notifications_off_outlined,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'Belum ada notifikasi baru',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Open Customer Service modal bottom sheet
  void _openCustomerService(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: Color(0xFFD97706),
                size: 38,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Layanan Bantuan & Helpdesk',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Butuh bantuan terkait akademik atau kendala aplikasi Smart Mahasiswa? Hubungi layanan bantuan resmi.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildCsActionTile(
              icon: Icons.chat_rounded,
              iconColor: const Color(0xFF10B981),
              iconBgColor: const Color(0xFFD1FAE5),
              title: 'WhatsApp Helpdesk',
              subtitle: 'Layanan cepat via WhatsApp resmi',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CsListPage()),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildCsActionTile(
              icon: Icons.help_center_rounded,
              iconColor: const Color(0xFF0284C7),
              iconBgColor: const Color(0xFFE0F2FE),
              title: 'Laporkan Kendala Teknis Aplikasi',
              subtitle: 'helpdesk.uinsalatiga.ac.id',
              onTap: () async {
                Navigator.pop(context);
                final uri = Uri.parse('https://helpdesk.uinsalatiga.ac.id');
                try {
                  final launched = await launchUrl(uri,
                      mode: LaunchMode.externalApplication);
                  if (!launched) {
                    await launchUrl(uri);
                  }
                } catch (_) {
                  try {
                    await launchUrl(uri);
                  } catch (_) {}
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCsActionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildSmallImportantMessage(String pesan, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.checkKrs.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pesan,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(60, 28),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              l10n.examine,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
