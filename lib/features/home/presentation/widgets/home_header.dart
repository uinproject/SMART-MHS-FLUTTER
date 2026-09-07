import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/home_helpers.dart';
import '../../../auth/data/models/login_data.dart';

class HomeHeader extends StatelessWidget {
  final LoginData user;

  const HomeHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return _buildIdentity(context);
  }

  Widget _buildIdentity(BuildContext context) {
    final tahunAngkatan = user.angkatan?.toString().substring(0, 4) ?? '2024';
    final nimOnlyNumber = user.nim?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    final profileUrl = 'https://si-mona.uinsalatiga.ac.id/user_log/view_image?angkatan=$tahunAngkatan&nim=$nimOnlyNumber';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(1.5),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: SizedBox(
            width: 34, // Slightly smaller
            height: 34,
            child: ClipOval(
              child: Image.network(
                profileUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.white,
                  child: const Icon(Icons.person, color: AppColors.primary, size: 20),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(color: Colors.white24);
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                SalamWaktu.getSalam(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 8.5, // Significantly smaller
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                user.nama?.split(' ').take(2).join(' ') ?? 'Mahasiswa',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12, // Significantly smaller
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget buildAcademicCard(LoginData user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), // Even softer shadow
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _academicItem('IP KUMULATIF', user.ipkKumulatif ?? '0.00', isLarge: true)),
              _verticalDivider(),
              Expanded(child: _statusItem(user)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          Row(
            children: [
              Expanded(child: _academicItem('SKS DITEMPUH', user.sksTempuh?.toString() ?? '0')),
              _verticalDivider(),
              Expanded(child: _academicItem('SEMESTER', user.semester?.toString() ?? '0')),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _academicItem(String label, String value, {bool isLarge = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: isLarge ? 24 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isLarge)
                const TextSpan(
                  text: ' / 4.00',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.normal),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _statusItem(LoginData user) {
    final statusText = StatusAkademik.getStatusText(user.status, user.semester, user.semester);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'STATUS MAHASISWA',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.success,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            statusText.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  static Widget _verticalDivider() {
    return Container(
      height: 35,
      width: 1,
      color: const Color(0xFFF1F5F9),
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}
