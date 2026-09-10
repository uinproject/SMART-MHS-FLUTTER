import 'package:flutter/material.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../storage/session_manager.dart';

/// Feature codes locked behind the (optional) subscription — values from the
/// legacy `jni/api-keys.c` (`Constanta.getkodeactivitykrs()` etc).
class SubscriptionGateFeatures {
  static const String krs = 'krs@115';
  static const String penawaranMk = 'pmk@114';
  static const String edom = 'ed@118';
  static const String khs = 'khs@116';
}

/// Port of the legacy `SubscriptionUtils.checkSubscription` — shows an
/// informational subscription dialog when ALL of these hold:
///  * `modesubscribe == "S"`
///  * student's angkatan >= `minangkatansubs`
///  * `lockfitur` contains [kodeFitur]
///  * now is past `batassubscribe` ("yyyy-MM-dd HH:mm:ss")
///
/// Dialog only — never blocks the feature (legacy behaviour).
void checkSubscription(BuildContext context, String kodeFitur) {
  final user = SessionManager().getUser();
  if (user == null) return;

  final modeSubs = user.modeSubscribe;
  final minAngkatan = int.tryParse(user.minAngkatanSubs ?? '');
  final lockFitur = user.lockFitur;
  final batasRaw = user.batasSubscribe;

  if (modeSubs != 'S' ||
      minAngkatan == null ||
      lockFitur == null ||
      !lockFitur.contains(kodeFitur)) {
    return;
  }

  // Legacy: angkatan.toString().substring(0, 4).toInt() (the intake year).
  final angkatanStr = (user.angkatan ?? 0).toString();
  if (angkatanStr.length < 4) return;
  final angkatan = int.tryParse(angkatanStr.substring(0, 4));
  if (angkatan == null || angkatan < minAngkatan) return;

  final batas = DateTime.tryParse((batasRaw ?? '').replaceAll(' ', 'T'));
  if (batas == null) return;
  if (DateTime.now().isBefore(batas) ||
      DateTime.now().isAtSameMomentAs(batas)) {
    return;
  }

  showDialog(
    context: context,
    builder: (dialogContext) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.secondary,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(dialogContext)!.subscriptionRequiredMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(AppLocalizations.of(dialogContext)!.okButton),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
