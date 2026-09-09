import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Unified app notification types (replaces every ad-hoc SnackBar / toast).
enum AppNotificationType { success, error, warning, info }

/// The one and only notification style of the app — a floating SnackBar with
/// a colored background and a leading icon, exactly like the KRS schedule
/// conflict error notification. Use this everywhere instead of building
/// SnackBars by hand, so all notifications look identical.
class AppNotifications {
  static void show(
    BuildContext context,
    String message, {
    AppNotificationType type = AppNotificationType.info,
    Duration duration = const Duration(seconds: 3),
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

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: duration,
      ));
  }
}
