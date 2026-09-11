import 'package:flutter/material.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/home_helpers.dart';
import '../../../../core/storage/session_manager.dart';
import '../../data/models/riwayat_akademik_response.dart';

Future<void> showRegistrationHistoryDialog({
  required BuildContext context,
  required List<RegistrasiItem> registrations,
}) {
  return showDialog(
    context: context,
    builder: (context) => RegistrationHistoryDialog(registrations: registrations),
  );
}

class RegistrationHistoryDialog extends StatelessWidget {
  final List<RegistrasiItem> registrations;

  const RegistrationHistoryDialog({super.key, required this.registrations});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentSemester = SessionManager().getUser()?.semester ?? 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.history_edu_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    l10n.registrationHistory,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: registrations.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final item = registrations[index];
                  return _buildRegistrationItem(context, item, l10n, currentSemester);
                },
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: Text(l10n.okButton, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationItem(
    BuildContext context,
    RegistrasiItem item,
    AppLocalizations l10n,
    int currentSemester,
  ) {
    final statusColor = StatusAkademik.getStatusColor(
      item.kodeStatus,
      item.semester,
      currentSemester,
      item.status,
    );
    final statusText = StatusAkademik.getStatusText(
      item.kodeStatus,
      item.semester,
      currentSemester,
      l10n,
      item.status,
    );
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.semester} ${item.semester}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  item.thsmt,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              statusText.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
