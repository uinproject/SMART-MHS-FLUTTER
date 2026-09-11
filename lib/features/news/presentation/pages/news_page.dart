import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/session_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/home_helpers.dart';
import '../../data/models/berita_response.dart';
import 'news_detail_page.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final ApiService _apiService = ApiService();
  final SessionManager _sessionManager = SessionManager();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<BeritaResponse> _newsList = [];
  List<BeritaResponse> _restoreNewsList = [];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isSearching = false;
  bool _isSearchOpen = false;
  bool _hasShownMaxSnackbar = false;

  // false = Berita Fakultas (default), true = Berita Rektorat
  bool _isRektorat = false;

  int _page = 1;
  static const int _totalPage = 10;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Memastikan context Flutter benar-benar siap sebelum pemanggilan API
    Future.microtask(() {
      _fetchNews(page: 1);
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
          _fetchNews(page: _page + 1, isAdd: true);
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

    final count = _newsList.length;
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

  Future<void> _fetchNews({
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
      final fetchedData = await _apiService.getBerita(
        isRektorat: _isRektorat,
        kodeFakultas: user?.kodeFakultas,
        page: page,
        perPage: 10,
        search: search,
      );

      if (!mounted) return;

      setState(() {
        if (isAdd) {
          _newsList.addAll(fetchedData);
          _page = page;
        } else if (_isSearching) {
          _newsList = List.from(fetchedData);
        } else {
          _newsList = List.from(fetchedData);
          _restoreNewsList = List.from(fetchedData);
          _page = 1;
        }
      });

      if (isAdd && fetchedData.isEmpty && !_hasShownMaxSnackbar) {
        _hasShownMaxSnackbar = true;
        _showMaxDataSnackbar();
      }
    } catch (_) {
      if (isAdd && !_hasShownMaxSnackbar) {
        _hasShownMaxSnackbar = true;
        _showMaxDataSnackbar();
      } else if (!isAdd) {
        setState(() {
          _newsList = [];
        });
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
        _fetchNews(page: 1, search: trimmed);
      } else {
        setState(() {
          _isSearching = false;
          _newsList = List.from(_restoreNewsList);
        });
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _debounceTimer?.cancel();
    setState(() {
      _isSearching = false;
      _newsList = List.from(_restoreNewsList);
    });
  }

  void _closeSearch() {
    _clearSearch();
    setState(() {
      _isSearchOpen = false;
    });
  }

  void _switchSource(bool isRektorat) {
    if (_isRektorat == isRektorat) return;
    setState(() {
      _isRektorat = isRektorat;
      _isSearching = false;
      _searchController.clear();
    });
    _fetchNews(page: 1);
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
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF003D82), Color(0xFF0056B3)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: _isSearchOpen
                          ? Container(
                              height: 46,
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
                                    _fetchNews(page: 1, search: trimmed);
                                  }
                                },
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                cursorColor: AppColors.primary,
                                decoration: InputDecoration(
                                  hintText: l10n.searchNewsHint,
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
                              l10n.news,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        _isSearchOpen
                            ? Icons.close_rounded
                            : Icons.search_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () {
                        if (_isSearchOpen) {
                          _closeSearch();
                        } else {
                          setState(() {
                            _isSearchOpen = true;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // Filter Segment: Berita Fakultas vs Berita Rektorat
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              color: Colors.white,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildFilterTab(
                        title: l10n.facultyNews,
                        isSelected: !_isRektorat,
                        icon: Icons.account_balance_rounded,
                        onTap: () => _switchSource(false),
                      ),
                    ),
                    Expanded(
                      child: _buildFilterTab(
                        title: l10n.rectorateNews,
                        isSelected: _isRektorat,
                        icon: Icons.domain_rounded,
                        onTap: () => _switchSource(true),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main News List with Pull-to-refresh
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  if (!_isSearching) {
                    _page = 1;
                    await _fetchNews(page: 1);
                  }
                },
                child: _buildBody(l10n),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab({
    required String title,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color:
                      isSelected ? AppColors.primary : const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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

    if (_newsList.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
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
                    Icons.newspaper_outlined,
                    size: 54,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noNewsFound,
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
      itemCount: _newsList.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _newsList.length) {
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

        final item = _newsList[index];
        return _buildNewsCard(item, l10n);
      },
    );
  }

  Widget _buildNewsCard(BeritaResponse item, AppLocalizations l10n) {
    final imageUrl = item.imageUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

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
                builder: (_) => NewsDetailPage(berita: item),
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
                            imageUrl,
                            width: 96,
                            height: 84,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                              child: Icon(
                                Icons.newspaper_rounded,
                                color: AppColors.primary,
                                size: 36,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.newspaper_rounded,
                              color: AppColors.primary,
                              size: 36,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge & Date
                      Row(
                        children: [
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
                              item.categoryName,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              FormatTanggalIndo.timeAgo(item.date, l10n),
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
                        item.displayTitle,
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

                      // Author / Publisher
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.authorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
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
