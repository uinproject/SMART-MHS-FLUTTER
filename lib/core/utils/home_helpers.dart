import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../theme/app_colors.dart';

class SalamWaktu {
  static String getSalam(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour <= 10) return l10n.goodMorning;
    if (hour >= 11 && hour <= 14) return l10n.goodAfternoon;
    if (hour >= 15 && hour <= 17) return l10n.goodEvening;
    return l10n.goodNight;
  }
}

class StatusAkademik {
  static String getStatusText(String? status, int? semester, int? currentSemester, AppLocalizations l10n) {
    switch (status) {
      case 'A': return l10n.statusActive;
      case 'C': return l10n.statusLeave;
      case 'K': return l10n.statusOut;
      case 'P': return l10n.statusMove;
      case 'L': return l10n.statusGraduated;
      case 'N':
        if (semester != null && currentSemester != null && semester < currentSemester) {
          return l10n.statusNonActive; // Or add a key for "Not Registered" specifically
        } else {
          return l10n.statusNonActive;
        }
      default: return l10n.statusDeath;
    }
  }

  static Color getStatusColor(String? status, int? semester, int? currentSemester) {
    switch (status) {
      case 'A': return AppColors.success;
      case 'C': return AppColors.secondary;
      case 'L': return AppColors.info;
      default: return AppColors.danger;
    }
  }
}

class FormatTanggalIndo {
  static String formatDateTime(String? dateStr, Locale locale) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr.replaceAll(' ', 'T'));
      final formatter = DateFormat('EEEE, dd MMMM yyyy HH:mm', locale.toString());
      return '${formatter.format(date)} WIB';
    } catch (e) {
      return '';
    }
  }

  static String timeAgo(String? dateStr, AppLocalizations l10n) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final cleanDate = dateStr.contains('T') ? dateStr : dateStr.replaceAll(' ', 'T');
      final date = DateTime.parse(cleanDate);
      final diff = DateTime.now().difference(date);
      
      if (diff.inSeconds < 60) return 'baru saja'; // Could add this to l10n too
      if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
      if (diff.inDays < 30) return '${diff.inDays} hari yang lalu';
      
      final months = (diff.inDays / 30).floor();
      if (months < 12) return '$months bulan yang lalu';
      
      final years = (diff.inDays / 365).floor();
      return '$years tahun yang lalu';
    } catch (e) {
      return dateStr;
    }
  }
}
