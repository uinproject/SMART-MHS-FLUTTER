import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/session_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/home_helpers.dart';
import '../../../home/data/models/pengumuman_response.dart';
import 'announcement_detail_page.dart';

class AnnouncementListPage extends StatefulWidget {
  const AnnouncementListPage({super.key});

  @override
  State<AnnouncementListPage> createState() => _AnnouncementListPageState();
}

class _AnnouncementListPageState extends State<AnnouncementListPage> {
  final ApiService _apiService = ApiService();
  final SessionManager _sessionManager = SessionManager();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<PengumumanData> _announcements = [];
  List<PengumumanData> _restoreAnnouncements = [];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isSearching = false;
  bool _hasShownMaxSnackbar = false;

  int _page = 1;
  static const int _totalPage = 10;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Memastikan context siap sebelum memanggil API (sesuai best practice Future.microtask)
    Future.microtask(() {
      _fetchAnnouncements(page: 1);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (currentScroll >= maxScroll - 60) {
      if (!_isLoading && !_isLoadingMore && !_isSearching) {
        if (_page < _totalPage) {
          _fetchAnnouncements(page: _page + 1, isAdd: true);
        } else if (_page >= _totalPage && !_hasShownMaxSnackbar) {
          _hasShownMaxSnackbar = true;
          _showMaxDataSnackbar();
        }
      }
    }
  }

  void _showMaxDataSnackbar() {
    final l10n = AppLocalizations.of(context);
    if (l10n == null || !mounted) return;

    final count = _announcements.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        backgroundColor: const Color(0xFF003D82),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.maxNewsLoaded(count),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _fetchAnnouncements({
    int page = 1,
    String? search,
    bool isAdd = false,
  }) async {
    if (!mounted) return;

    if (isAdd) {
      setState(() {
        _isLoadingMore = true;
      });
    } else {
      setState(() {
        _isLoading = true;
        _hasShownMaxSnackbar = false;
      });
    }

    try {
      final user = _sessionManager.getUser();
      final response = await _apiService.getPengumuman(
        nim: user?.nim,
        kodeJen: user?.kodeJen,
        kodeFak: user?.kodeFakultas,
        kodePst: user?.kodePst,
        page: page,
        search: search,
      );

      if (!mounted) return;

      if (response != null && response.success && response.data != null) {
        final List<PengumumanData> fetchedData = response.data!;
        setState(() {
          if (isAdd) {
            _announcements.addAll(fetchedData);
            _page = page;
          } else if (_isSearching) {
            _announcements = List.from(fetchedData);
          } else {
            _announcements = List.from(fetchedData);
            _restoreAnnouncements = List.from(fetchedData);
            _page = 1;
          }
        });

        // Jika data baru kosong pada pagination berikutnya, tampilkan info
        if (isAdd && fetchedData.isEmpty && !_hasShownMaxSnackbar) {
          _hasShownMaxSnackbar = true;
          _showMaxDataSnackbar();
        }
      } else {
        if (!isAdd) {
          setState(() {
            _announcements = [];
          });
        }
      }
    } catch (_) {
      if (isAdd && !_hasShownMaxSnackbar) {
        _hasShownMaxSnackbar = true;
        _showMaxDataSnackbar();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 450), () {
      final trimmed = query.trim();
      if (trimmed.isNotEmpty) {
        setState(() {
          _isSearching = true;
        });
        _fetchAnnouncements(page: 1, search: trimmed);
      } else {
        setState(() {
          _isSearching = false;
          _announcements = List.from(_restoreAnnouncements);
        });
      }
    });
  }

  bool _isSearchOpen = false;

  void _clearSearch() {
    _searchController.clear();
    _debounceTimer?.cancel();
    setState(() {
      _isSearching = false;
      _announcements = List.from(_restoreAnnouncements);
    });
  }

  void _closeSearch() {
    _clearSearch();
    setState(() {
      _isSearchOpen = false;
    });
  }

  String _stripHtml(String htmlString) {
    final exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true);
    String result = htmlString.replaceAll(exp, '');
    result = result
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
    return result.trim();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: !_isSearchOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSearchOpen) {
          _closeSearch();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            color: AppColors.primary,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        if (_isSearchOpen) {
                          _closeSearch();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    Expanded(
                      child: _isSearchOpen
                          ? Container(
                              height: 46,
                              margin:
                                  const EdgeInsets.only(right: 12, left: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                onChanged: (val) {
                                  setState(() {});
                                  _onSearchChanged(val);
                                },
                                onSubmitted: (val) {
                                  final trimmed = val.trim();
                                  if (trimmed.isNotEmpty) {
                                    setState(() {
                                      _isSearching = true;
                                    });
                                    _fetchAnnouncements(
                                      page: 1,
                                      search: trimmed,
                                    );
                                  }
                                },
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                cursorColor: AppColors.primary,
                                decoration: InputDecoration(
                                  hintText: l10n.searchAnnouncementHint,
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.cancel_rounded,
                                            color: Color(0xFF94A3B8),
                                            size: 20,
                                          ),
                                          onPressed: _clearSearch,
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            )
                          : Text(
                              l10n.announcements,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    if (!_isSearchOpen)
                      IconButton(
                        icon: const Icon(
                          Icons.search_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () {
                          setState(() {
                            _isSearchOpen = true;
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            if (!_isSearching) {
              _page = 1;
              await _fetchAnnouncements(page: 1);
            }
          },
          child: _buildBody(l10n),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(
        child: SpinKitThreeBounce(
          color: AppColors.primary,
          size: 28,
        ),
      );
    }

    if (_announcements.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.campaign_outlined,
                    size: 54,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noAnnouncementsFound,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _announcements.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _announcements.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SpinKitThreeBounce(
                color: AppColors.primary,
                size: 24,
              ),
            ),
          );
        }

        final item = _announcements[index];
        return _buildAnnouncementItem(item, l10n);
      },
    );
  }

  Widget _buildAnnouncementItem(PengumumanData item, AppLocalizations l10n) {
    final hasImage = item.linkPicture.trim().isNotEmpty;
    final snippet = _stripHtml(item.isi);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AnnouncementDetailPage(pengumuman: item),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 96,
                    height: 84,
                    color: const Color(0xFFF1F5F9),
                    child: hasImage
                        ? Image.network(
                            item.linkPicture,
                            width: 96,
                            height: 84,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                              child: Icon(
                                Icons.campaign_rounded,
                                color: AppColors.primary,
                                size: 36,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.campaign_rounded,
                              color: AppColors.primary,
                              size: 36,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),

                // Text Information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge & Date Row
                      Row(
                        children: [
                          if (item.kategori.trim().isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.09),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.kategori.trim(),
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              FormatTanggalIndo.timeAgo(item.tanggal, l10n),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Title
                      Text(
                        item.judul,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Snippet
                      if (snippet.isNotEmpty)
                        Text(
                          snippet,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
