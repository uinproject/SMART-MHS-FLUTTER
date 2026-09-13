import 'package:flutter/material.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// Modern Shimmer loading skeleton for the Home Announcement Carousel.
/// Smoothly animates a shining gradient sweep to indicate loading state.
class AnnouncementShimmer extends StatefulWidget {
  const AnnouncementShimmer({super.key});

  @override
  State<AnnouncementShimmer> createState() => _AnnouncementShimmerState();
}

class _AnnouncementShimmerState extends State<AnnouncementShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final announcementsTitle = l10n?.announcements ?? 'Pengumuman';
    final showMoreText = l10n?.showMore ?? 'Lihat Semua';

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row (Pengumuman & Lihat Semua)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    announcementsTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        showMoreText,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Shimmer Card matching AnnouncementCarousel layout
            Container(
              height: 165,
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Left side: Text elements skeleton
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Time / Category pill
                          _buildShimmerBox(
                            width: 75,
                            height: 12,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          const SizedBox(height: 10),
                          // Title line 1
                          _buildShimmerBox(
                            width: double.infinity,
                            height: 14,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          const SizedBox(height: 6),
                          // Title line 2
                          _buildShimmerBox(
                            width: 120,
                            height: 14,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          const SizedBox(height: 10),
                          // Subtitle snippet
                          _buildShimmerBox(
                            width: 90,
                            height: 10,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Right side: Image skeleton
                  Expanded(
                    flex: 4,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      child: _buildShimmerBox(
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Subtle Dots skeleton below
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildShimmerBox(
                    width: 18,
                    height: 5,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(width: 6),
                  _buildShimmerBox(
                    width: 6,
                    height: 5,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(width: 6),
                  _buildShimmerBox(
                    width: 6,
                    height: 5,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Shimmer element with animated sweep shader
  Widget _buildShimmerBox({
    required double width,
    required double height,
    required BorderRadius borderRadius,
  }) {
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: const Alignment(-1.5, -0.3),
          end: const Alignment(1.5, 0.3),
          stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
          colors: const [
            Color(0xFFE2E8F0),
            Color(0xFFE2E8F0),
            Color(0xFFF8FAFC),
            Color(0xFFE2E8F0),
            Color(0xFFE2E8F0),
          ],
          transform: _SlidingGradientTransform(slidePercent: _controller.value),
        ).createShader(bounds);
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 2 - 1),
      0.0,
      0.0,
    );
  }
}
