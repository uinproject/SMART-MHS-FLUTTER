import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pinput/pinput.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/utils/app_notifications.dart';
import '../../../../core/storage/session_manager.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../home/presentation/pages/main_page.dart';

class OtpVerificationPage extends StatefulWidget {
  final String email;
  final int initialCountdown;

  const OtpVerificationPage({
    super.key,
    required this.email,
    required this.initialCountdown,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _otpController = TextEditingController();
  final _apiService = ApiService();
  final _sessionManager = SessionManager();

  bool _isLoading = false;
  String? _errorMessage;
  int _secondsRemaining = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.initialCountdown > 0) {
      _startTimer(widget.initialCountdown);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    setState(() => _secondsRemaining = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    final mins = (seconds / 60).floor().toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$mins:$secs";
  }

  Future<void> _handleVerifyOtp() async {
    if (_otpController.text.length < 4) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = _sessionManager.getUser();
    if (user == null) return;

    try {
      final response = await _apiService.verifyOtp(
        nim: user.nim ?? '',
        kdpst: user.kodePst ?? '',
        email: widget.email,
        otp: _otpController.text,

      );

      if (response != null) {
        final bool success = response['success'] ?? false;
        final String message = response['message'] ?? '';

        if (success) {
          await _sessionManager.setEmailVerified(true);
          if (!mounted) return;
          _showSuccessDialog(message);
        } else {
          setState(() => _errorMessage = message);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = AppLocalizations.of(context)!.systemError);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResendOtp() async {
    if (_secondsRemaining > 0) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = _sessionManager.getUser();
    if (user == null) return;

    try {
      final response = await _apiService.getOtp(
        nim: user.nim ?? '',
        kdpst: user.kodePst ?? '',
        email: widget.email,

      );

      if (response != null) {
        final bool success = response['success'] ?? false;
        final String message = response['message'] ?? '';
        final int countdown = response['countdown'] ?? 0;

        if (success) {
          _startTimer(countdown);
          if (!mounted) return;
          AppNotifications.show(
            context,
            message,
            type: AppNotificationType.success,
          );
        } else {
          setState(() => _errorMessage = message);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = AppLocalizations.of(context)!.resendOtpFailed);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String message) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.success,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final navigator = Navigator.of(context, rootNavigator: true);
                    Navigator.pop(context);
                    navigator.pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const MainPage()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(l10n.ok, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    final defaultPinTheme = PinTheme(
      width: 60,
      height: 64,
      textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.45,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF0056B3), Color(0xFF003D82), Color(0xFF002452)],
              ),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(80)),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.security_rounded, color: Colors.white, size: 60),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Column(
                    children: [
                      Text(
                        l10n.otpVerif.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 4),
                      Container(width: 40, height: 3, decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(2))),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [BoxShadow(color: const Color(0xFF003D82).withValues(alpha: 0.08), blurRadius: 40, offset: const Offset(0, 20))],
                    ),
                    child: Column(
                      children: [
                        Text(l10n.enterOtp, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                        const SizedBox(height: 12),
                        Text(StringUtils.maskEmail(widget.email), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 40),
                        Pinput(
                          length: 4,
                          controller: _otpController,
                          defaultPinTheme: defaultPinTheme,
                          focusedPinTheme: defaultPinTheme.copyWith(
                            decoration: defaultPinTheme.decoration!.copyWith(border: Border.all(color: AppColors.primary, width: 2)),
                          ),
                          onCompleted: (pin) => _handleVerifyOtp(),
                        ),
                        const SizedBox(height: 32),
                        if (_errorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.danger.withValues(alpha: 0.2))),
                            child: Text(_errorMessage!, style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                          ),
                          const SizedBox(height: 20),
                        ],
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleVerifyOtp,
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), elevation: 0),
                            child: _isLoading ? const SpinKitThreeBounce(color: Colors.white, size: 20) : Text(l10n.verify.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${l10n.didNotReceiveCode} ',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                            TextButton(
                              onPressed: _secondsRemaining == 0 ? _handleResendOtp : null,
                              child: Text(
                                _secondsRemaining == 0 ? l10n.resendOtp : "${l10n.wait} (${_formatTime(_secondsRemaining)})",
                                style: TextStyle(color: _secondsRemaining == 0 ? AppColors.secondary : AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
