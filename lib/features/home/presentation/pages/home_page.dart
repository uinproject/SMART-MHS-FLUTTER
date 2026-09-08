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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = _sessionManager.getUser();
    final l10n = AppLocalizations.of(context)!;
    
    if (user == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    const mainGradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [Color(0xFF003D82), Color(0xFF0056B3)],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => _loadData(isRefresh: true),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverAppBar(
              pinned: true,
              toolbarHeight: 70,
              backgroundColor: const Color(0xFF003D82),
              elevation: 0,
              automaticallyImplyLeading: false,
              titleSpacing: 20,
              title: HomeHeader(user: user),
              centerTitle: false,
              flexibleSpace: Container(
                decoration: const BoxDecoration(gradient: mainGradient),
              ),
            ),
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 50,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: mainGradient,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
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
