import 'dart:async';

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Unified app notification types (replaces every ad-hoc SnackBar / toast).
enum AppNotificationType { success, error, warning, info }

/// Where the notification appears. [top] (default) renders a floating
/// banner below the app bar via the root [Overlay]; [bottom] keeps the
/// classic floating SnackBar behaviour.
enum AppNotificationPosition { top, bottom }

/// The one and only notification style of the app — a floating banner with
/// a colored background and a leading icon, exactly like the KRS schedule
/// conflict error notification. Use this everywhere instead of building
/// SnackBars by hand, so all notifications look identical.
class AppNotifications {
  /// Currently visible top banner (replaced by the next one, mimicking
  /// `hideCurrentSnackBar`).
  static OverlayEntry? _topEntry;

  static void show(
    BuildContext context,
    String message, {
    AppNotificationType type = AppNotificationType.info,
    Duration duration = const Duration(seconds: 3),
    AppNotificationPosition position = AppNotificationPosition.top,
  }) {
    final Color color;
    final IconData icon;
    switch (type) {
      case AppNotificationType.success:
        color = AppColors.success;
        icon = Icons.check_circle_rounded;
      case AppNotificationType.error:
        color = AppColors.danger;
        icon = Icons.error_outline_rounded;
      case AppNotificationType.warning:
        color = AppColors.secondary;
        icon = Icons.warning_amber_rounded;
      case AppNotificationType.info:
        color = AppColors.info;
        icon = Icons.info_rounded;
    }

    if (position == AppNotificationPosition.bottom) {
      _showSnackBar(
        context,
        message,
        color: color,
        icon: icon,
        duration: duration,
      );
      return;
    }

    // Top banner via the root overlay (fallback to SnackBar when no
    // overlay is available, e.g. outside a navigator).
    _topEntry?.remove();
    _topEntry = null;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      _showSnackBar(
        context,
        message,
        color: color,
        icon: icon,
        duration: duration,
      );
      return;
    }

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TopNotificationBanner(
        color: color,
        icon: icon,
        message: message,
        duration: duration,
        onDismissed: () {
          // Only remove when THIS banner is still the current one — it may
          // have been replaced (and removed) by a newer notification.
          if (_topEntry == entry) {
            _topEntry!.remove();
            _topEntry = null;
          }
        },
      ),
    );
    _topEntry = entry;
    overlay.insert(entry);
  }

  static void _showSnackBar(
    BuildContext context,
    String message, {
    required Color color,
    required IconData icon,
    required Duration duration,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message, style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: duration,
        ),
      );
  }
}

/// Floating banner pinned at the top of the screen; slides in from above,
/// auto-dismisses after [duration] (or on tap) with a slide-out animation.
class _TopNotificationBanner extends StatefulWidget {
  final Color color;
  final IconData icon;
  final String message;
  final Duration duration;
  final VoidCallback onDismissed;

  const _TopNotificationBanner({
    required this.color,
    required this.icon,
    required this.message,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_TopNotificationBanner> createState() => _TopNotificationBannerState();
}

class _TopNotificationBannerState extends State<_TopNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    Timer(widget.duration, _close);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() {
    if (_closing || !mounted) return;
    _closing = true;
    _controller.reverse().whenComplete(widget.onDismissed);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, -1.2), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
            ),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
          child: SafeArea(
            minimum: const EdgeInsets.only(top: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                color: widget.color,
                borderRadius: BorderRadius.circular(14),
                elevation: 6,
                shadowColor: Colors.black.withValues(alpha: 0.25),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _close,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(widget.icon, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
