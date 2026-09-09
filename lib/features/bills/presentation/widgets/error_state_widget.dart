import 'package:flutter/material.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// Which failure state to render (mirrors the 3 failure branches of the
/// legacy `show_data()`: no data / server error message / no internet).
enum ErrorStateType { noData, serverError, noInternet }

/// Scrollable error/empty state usable inside a [RefreshIndicator]
/// (pull-to-refresh still works, same as the legacy SwipeRefreshLayout).
class ErrorStateWidget extends StatelessWidget {
  final ErrorStateType type;

  /// Text shown for [ErrorStateType.noData] (page-specific i18n message).
  final String? noDataMessage;

  /// Server/API message shown for [ErrorStateType.serverError].
  final String? serverMessage;

  /// Icon shown for [ErrorStateType.noData] (page-specific).
  final IconData noDataIcon;

  const ErrorStateWidget({
    super.key,
    required this.type,
    this.noDataMessage,
    this.serverMessage,
    this.noDataIcon = Icons.receipt_long_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final IconData icon;
    final Color color;
    final String message;

    switch (type) {
      case ErrorStateType.noData:
        icon = noDataIcon;
        color = AppColors.primary;
        message = noDataMessage ?? l10n.noActiveBills;
      case ErrorStateType.serverError:
        icon = Icons.error_outline_rounded;
        color = AppColors.danger;
        message = (serverMessage == null || serverMessage!.isEmpty)
            ? l10n.noActiveBills
            : serverMessage!;
      case ErrorStateType.noInternet:
        icon = Icons.wifi_off_rounded;
        color = AppColors.danger;
        message = l10n.checkConnection;
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
        Icon(icon, size: 80, color: color.withValues(alpha: 0.25)),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
