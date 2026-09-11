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
  static String normalizeStatusCode(String? code, [String? statusText]) {
    final c = code?.trim().toUpperCase();
    if (c == 'A' || c == 'C' || c == 'L' || c == 'N' || c == 'K' || c == 'P' || c == 'D') {
      return c!;
    }
    if (c == '1') return 'A';
    if (c == '2') return 'C';
    if (c == '0') return 'N';

    final text = (statusText ?? '').toLowerCase();
    if (text.contains('aktif') && !text.contains('non')) return 'A';
    if (text.contains('cuti')) return 'C';
    if (text.contains('lulus')) return 'L';
    if (text.contains('keluar') || text.contains('drop')) return 'K';
    if (text.contains('pindah')) return 'P';
    if (text.contains('non') || text.contains('tidak registrasi') || text.contains('belum')) return 'N';
    if (text.contains('meninggal')) return 'D';

    return c ?? '';
  }

  static String getStatusText(String? status, int? semester, int? currentSemester, AppLocalizations l10n, [String? fallbackText]) {
    final code = normalizeStatusCode(status, fallbackText);
    switch (code) {
      case 'A': return l10n.statusActive;
      case 'C': return l10n.statusLeave;
      case 'K': return l10n.statusOut;
      case 'P': return l10n.statusMove;
      case 'L': return l10n.statusGraduated;
      case 'N':
        return l10n.statusNonActive;
      case 'D':
        return l10n.statusDeath;
      default:
        if (fallbackText != null && fallbackText.isNotEmpty) {
          return fallbackText;
        }
        return l10n.statusDeath;
    }
  }

  static Color getStatusColor(String? status, int? semester, int? currentSemester, [String? fallbackText]) {
    final code = normalizeStatusCode(status, fallbackText);
    switch (code) {
      case 'A': return AppColors.success;
      case 'C': return AppColors.secondary;
      case 'L': return AppColors.info;
      case 'P': return AppColors.primary;
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
      
      if (diff.inSeconds < 60) return l10n.justNow;
      if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
      if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
      if (diff.inDays < 30) return l10n.daysAgo(diff.inDays);
      
      final months = (diff.inDays / 30).floor();
      if (months < 12) return l10n.monthsAgo(months);
      
      final years = (diff.inDays / 365).floor();
      return l10n.yearsAgo(years);
    } catch (e) {
      return dateStr;
    }
  }
}
