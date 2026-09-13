import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/session_manager.dart';
import '../../../auth/presentation/pages/otp_reset_password_page.dart';

class ChangePasswordUseOldPassPage extends StatefulWidget {
  const ChangePasswordUseOldPassPage({super.key});

  @override
  State<ChangePasswordUseOldPassPage> createState() =>
      _ChangePasswordUseOldPassPageState();
}

class _ChangePasswordUseOldPassPageState
    extends State<ChangePasswordUseOldPassPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apiService = ApiService();
  final _sessionManager = SessionManager();

  bool _isLoading = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  // Forgot old password countdown
  bool _isForgotCooldown = false;
  Timer? _countdownTimer;
  int _countdownSeconds = 0;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _newPasswordController.removeListener(_onPasswordChanged);
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // Password strength helpers
  bool get _hasMinLength => _newPasswordController.text.length >= 8;
  bool get _hasUpper => RegExp(r'[A-Z]').hasMatch(_newPasswordController.text);
  bool get _hasLower => RegExp(r'[a-z]').hasMatch(_newPasswordController.text);
  bool get _hasUpperLower => _hasUpper && _hasLower;
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_newPasswordController.text);
  bool get _hasSpecial =>
      RegExp(r'[^a-zA-Z0-9]').hasMatch(_newPasswordController.text);

  bool get _isPasswordStrong =>
      _hasMinLength && _hasUpperLower && _hasNumber && _hasSpecial;

  int get _passwordStrengthScore {
    final text = _newPasswordController.text;
    if (text.isEmpty) return 0;
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasUpperLower) score++;
    if (_hasNumber) score++;
    if (_hasSpecial) score++;

    if (score == 4) return 3; // Kuat
    if (score >= 2) return 2; // Sedang
    return 1; // Lemah
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isPasswordStrong) {
      setState(
          () => _errorMessage = AppLocalizations.of(context)!.passMustBeStrong);
      return;
    }

    final user = _sessionManager.getUser();
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final language = Localizations.localeOf(context).languageCode;
      final response = await _apiService.changePasswordUseOldPass(
        nim: user.nim ?? '',
        oldPassword: _oldPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
        email: user.email ?? '',
        language: language,
      );

      if (response != null) {
        if (response.success) {
          if (!mounted) return;
          _showSuccessDialog(response.message);
        } else {
          setState(() => _errorMessage = response.message);
        }
      } else {
        if (mounted) {
          setState(() => _errorMessage =
              AppLocalizations.of(context)!.updatePasswordFailed);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(
            () => _errorMessage = AppLocalizations.of(context)!.systemError);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotOldPassword() async {
    final user = _sessionManager.getUser();
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getOtpResetPassword(
        nim: user.nim ?? '',
        email: user.email ?? '',
      );

      if (response != null) {
        final success = response['success'] ?? false;
        final countdown = response['countdown'] ?? 0;
        final message = response['message'] ?? '';

        if (success) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          // Navigate directly to OTP verification screen, matching Kotlin behavior
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OtpResetPasswordPage(
                nim: user.nim ?? '',
                email: user.email ?? '',
                initialCountdown: countdown,
              ),
            ),
          );
        } else {
          if (countdown > 0) {
            _startCountdown(countdown);
            setState(() {
              _isLoading = false;
              _errorMessage = message;
            });
          } else {
            setState(() {
              _isLoading = false;
              _errorMessage = message;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                AppLocalizations.of(context)!.serverConnectionFailed;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = AppLocalizations.of(context)!.systemError;
        });
      }
    }
  }

  void _startCountdown(int seconds) {
    _countdownTimer?.cancel();
    setState(() {
      _isForgotCooldown = true;
      _countdownSeconds = seconds;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds <= 0) {
        timer.cancel();
        if (mounted) {
          setState(() => _isForgotCooldown = false);
        }
      } else {
        if (mounted) {
          setState(() => _countdownSeconds--);
        }
      }
    });
  }

  String get _countdownText {
    final minutes = (_countdownSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_countdownSeconds % 60).toString().padLeft(2, '0');
    return '${AppLocalizations.of(context)!.waitOtp} ($minutes:$seconds)';
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
                child: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.success,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Return to previous page (SecurityPage)
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
    final user = _sessionManager.getUser();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Text(
          l10n.changePassword,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.vpn_key_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        l10n.changePassUseOldInstruction,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Error message
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.danger,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Form card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Old password field
                    _buildTextField(
                      controller: _oldPasswordController,
                      label: l10n.oldPassword.toUpperCase(),
                      hint: l10n.enterOldPassword,
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      obscureText: _obscureOldPassword,
                      onToggleVisibility: () =>
                          setState(() => _obscureOldPassword = !_obscureOldPassword),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.oldPassRequired;
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // New password field
                    _buildTextField(
                      controller: _newPasswordController,
                      label: l10n.newPassword.toUpperCase(),
                      hint: l10n.enterNewPassword,
                      icon: Icons.lock_rounded,
                      isPassword: true,
                      obscureText: _obscureNewPassword,
                      onToggleVisibility: () =>
                          setState(() => _obscureNewPassword = !_obscureNewPassword),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.newPassRequired;
                        }
                        if (value.length < 8) return l10n.passMinLength;
                        if (!RegExp(r'[a-z]').hasMatch(value) ||
                            !RegExp(r'[A-Z]').hasMatch(value)) {
                          return l10n.passMustContainUpperLower;
                        }
                        if (!RegExp(r'[0-9]').hasMatch(value)) {
                          return l10n.passMustContainNumber;
                        }
                        if (!RegExp(r'[^a-zA-Z0-9]').hasMatch(value)) {
                          return l10n.passMustContainSpecial;
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // Password strength indicator
                    _buildPasswordStrengthSection(l10n),

                    const SizedBox(height: 20),

                    // Confirm password field
                    _buildTextField(
                      controller: _confirmPasswordController,
                      label: l10n.confirmPassword.toUpperCase(),
                      hint: l10n.confirmNewPasswordHint,
                      icon: Icons.lock_clock_outlined,
                      isPassword: true,
                      obscureText: _obscureConfirmPassword,
                      onToggleVisibility: () => setState(
                          () => _obscureConfirmPassword = !_obscureConfirmPassword),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.confPassRequired;
                        }
                        if (value != _newPasswordController.text) {
                          return l10n.passNotMatch;
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 28),

                    // Change password button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleChangePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SpinKitThreeBounce(
                                color: Colors.white,
                                size: 20,
                              )
                            : Text(
                                l10n.savePassword.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Forgot old password link — only show if email is verified
              if (user != null && user.emailVerification)
                Center(
                  child: TextButton(
                    onPressed:
                        (_isLoading || _isForgotCooldown) ? null : _handleForgotOldPassword,
                    child: Text(
                      _isForgotCooldown
                          ? _countdownText
                          : l10n.forgotOldPassword,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: (_isLoading || _isForgotCooldown)
                            ? AppColors.textSecondary
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Password strength section (same as change_password_page.dart)
  // ─────────────────────────────────────────────
  Widget _buildPasswordStrengthSection(AppLocalizations l10n) {
    final text = _newPasswordController.text;
    final score = _passwordStrengthScore;

    String labelText;
    Color statusColor;
    Color statusBgColor;

    if (score == 3) {
      labelText = l10n.passwordStrengthStrong;
      statusColor = const Color(0xFF059669);
      statusBgColor = const Color(0xFFECFDF5);
    } else if (score == 2) {
      labelText = l10n.passwordStrengthMedium;
      statusColor = const Color(0xFFD97706);
      statusBgColor = const Color(0xFFFFFBEB);
    } else if (score == 1) {
      labelText = l10n.passwordStrengthWeak;
      statusColor = const Color(0xFFDC2626);
      statusBgColor = const Color(0xFFFEF2F2);
    } else {
      labelText = '';
      statusColor = const Color(0xFF94A3B8);
      statusBgColor = Colors.transparent;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.passwordStrengthLabel,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            if (text.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  labelText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // 3-Segment Progress Bar
        Row(
          children: [
            Expanded(
              child: _buildBarSegment(
                active: score >= 1,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildBarSegment(
                active: score >= 2,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildBarSegment(
                active: score >= 3,
                color: statusColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Requirements checklist
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            children: [
              _buildCriteriaItem(
                label: l10n.passwordReqMinLength,
                isMet: _hasMinLength,
              ),
              const SizedBox(height: 8),
              _buildCriteriaItem(
                label: l10n.passwordReqUpperLower,
                isMet: _hasUpperLower,
              ),
              const SizedBox(height: 8),
              _buildCriteriaItem(
                label: l10n.passwordReqNumber,
                isMet: _hasNumber,
              ),
              const SizedBox(height: 8),
              _buildCriteriaItem(
                label: l10n.passwordReqSpecial,
                isMet: _hasSpecial,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBarSegment({required bool active, required Color color}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 5,
      decoration: BoxDecoration(
        color: active ? color : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildCriteriaItem({required String label, required bool isMet}) {
    return Row(
      children: [
        Icon(
          isMet
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 16,
          color: isMet ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
              color:
                  isMet ? const Color(0xFF1E293B) : const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          enabled: !_isLoading,
          obscureText: isPassword && obscureText,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: const Color(0xFF94A3B8),
                      size: 20,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide:
                  const BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
