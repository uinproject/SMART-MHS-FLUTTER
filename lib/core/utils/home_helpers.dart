import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

class SalamWaktu {
  static String getSalam() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour <= 10) return 'Selamat Pagi';
    if (hour >= 11 && hour <= 14) return 'Selamat Siang';
    if (hour >= 15 && hour <= 17) return 'Selamat Sore';
    return 'Selamat Malam';
  }
}

class StatusAkademik {
  static String getStatusText(String? status, int? semester, int? currentSemester) {
    switch (status) {
      case 'A': return 'Aktif';
      case 'C': return 'Cuti';
      case 'K': return 'Keluar';
      case 'P': return 'Pindah';
      case 'L': return 'Lulus';
      case 'N':
        if (semester != null && currentSemester != null && semester < currentSemester) {
          return 'Tidak Registrasi';
        } else {
          return 'Belum Registrasi';
        }
      default: return 'Meninggal Dunia';
    }
  }

  static Color getStatusColor(String? status, int? semester, int? currentSemester) {
    switch (status) {
      case 'A': return AppColors.success;
      case 'C': return AppColors.secondary;
      case 'K': return AppColors.danger;
      case 'P': return AppColors.primary;
      case 'L': return AppColors.info;
      case 'N':
        if (semester != null && currentSemester != null && semester < currentSemester) {
          return AppColors.danger;
        } else {
          return AppColors.secondary;
        }
      default: return AppColors.danger;
    }
  }
}

class FormatTanggalIndo {
  static String formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr.replaceAll(' ', 'T'));
      final formatter = DateFormat('EEEE, dd MMMM yyyy HH:mm', 'id_ID');
      return '${formatter.format(date)} WIB';
    } catch (e) {
      return '';
    }
  }

  static String timeAgo(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      // Handle "yyyy-MM-dd HH:mm:ss" format by converting to ISO
      final cleanDate = dateStr.contains('T') ? dateStr : dateStr.replaceAll(' ', 'T');
      final date = DateTime.parse(cleanDate);
      final diff = DateTime.now().difference(date);
      
      if (diff.inSeconds < 60) return 'baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
      if (diff.inDays < 30) return '${diff.inDays} hari yang lalu';
      
      final months = (diff.inDays / 30).floor();
      if (months < 12) return '$months bulan yang lalu';
      
      final years = (diff.inDays / 365).floor();
      return '$years tahun yang lalu';
    } catch (e) {
      return dateStr; // Fallback to original string
    }
  }
}
