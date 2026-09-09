import 'package:flutter/material.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/session_manager.dart';
import '../widgets/home_header.dart';
import '../widgets/main_menu_grid.dart';
import '../widgets/announcement_carousel.dart';
import '../../data/models/pengumuman_response.dart';
import 'package:smartmahsiswaflutter/features/auth/presentation/pages/login_screen.dart';
import '../../../../core/utils/device_utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  final _apiService = ApiService();
  final _sessionManager = SessionManager();

  PengumumanResponse? _pengumuman;
  bool _isLoading = true;

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
          kodeJen: user.kodeJen,
          kodeFak: user.kodeFakultas,
          kodePst: user.kodePst,
        );

        if (mounted) {
          setState(() {
            _pengumuman = pengumuman;
            _isLoading = false;
          });
        }
      }
    } on ForceLogoutException catch (_) {
      final navigator = Navigator.of(context, rootNavigator: true);
      await _sessionManager.clear();
      if (mounted) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Satu sumber gradient yang dipakai di SliverAppBar & kotak rounded di
  // bawahnya, supaya keduanya benar-benar identik dan tidak ada "sambungan"
  // warna yang kelihatan, dalam kondisi apa pun (termasuk saat overscroll
  // pull-to-refresh).
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      Color(0xFF002B5C), // navy lebih dalam, kesan lebih premium
      Color(0xFF003D82),
      Color(0xFF0062CC),
    ],
    stops: [0.0, 0.55, 1.0],
  );

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
      body: RefreshIndicator(
        color: const Color(0xFF003D82),
        onRefresh: () => _loadData(isRefresh: true),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverAppBar(
              pinned: true,
              toolbarHeight: 70,
              backgroundColor: const Color(0xFF002B5C),
              elevation: 0,
              // Kunci hilangnya "pemisah" saat refresh indicator aktif:
              // Material 3 default-nya menambahkan shadow + tint begitu
              // konten dianggap "scrolled under" app bar (termasuk saat
              // gesture pull-to-refresh). Matikan semuanya di sini.
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.transparent,
              automaticallyImplyLeading: false,
              titleSpacing: 20,
              title: HomeHeader(user: user),
              centerTitle: false,
              flexibleSpace: Container(
                decoration: const BoxDecoration(gradient: headerGradient),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      right: -20,
                      top: -30,
                      child: _glowCircle(90, 0.08),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -40,
                      child: _glowCircle(70, 0.06),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [

                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                    child: HomeHeader.buildAcademicCard(user, l10n),
                  ),
                ],
              ),
            ),
            if (_pengumuman?.pesanPenting != null && _pengumuman!.pesanPenting!.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildSmallImportantMessage(_pengumuman!.pesanPenting!, l10n),
              ),
            const SliverToBoxAdapter(
              child: MainMenuGrid(),
            ),
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
            const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
          ],
        ),
      ),
    );
  }

  // Aksen lingkaran halus untuk kesan header lebih modern/premium.
  Widget _glowCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
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
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  pesan,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(l10n.examine, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}