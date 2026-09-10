import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// General-purpose blocking dialog that directs the user to complete a
/// required action before continuing (fill EDOM, fill a survey, etc.).
///
/// Port of the legacy `dialog_show_eval_notif` (cutom_dialog_one_button /
/// custom_dialog_two_button):
/// - [dismissible] false -> one-button blocking dialog (legacy
///   InputPenawaranMk: must fill the evaluation, feature stays hidden)
/// - [dismissible] true -> two-button dialog with a cancel option (legacy
///   HomeFragment: informational reminder)
///
/// The action itself is fully generic — the caller decides where to go.
Future<void> showActionRequiredDialog({
  required BuildContext context,
  required String message,
  required String actionLabel,
  required VoidCallback onAction,
  String? cancelLabel,
  bool dismissible = false,
  IconData icon = Icons.star_rounded,
  Color iconColor = Colors.amber,
  Color iconBackground = Colors.amber,
}) {
  return showDialog(
    context: context,
    barrierDismissible: dismissible,
    builder: (dialogContext) => PopScope(
      canPop: dismissible,
      child: Dialog(
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
                  color: iconBackground.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              if (dismissible && cancelLabel != null)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(cancelLabel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          onAction();
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(actionLabel),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      onAction();
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(actionLabel),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
