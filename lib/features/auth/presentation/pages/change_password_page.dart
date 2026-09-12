import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';
import 'login_screen.dart';

class ChangePasswordPage extends StatefulWidget {
  final String encNim;
  final String email;
  final String otp;

  const ChangePasswordPage({
    super.key,
    required this.encNim,
    required this.email,
    required this.otp,
  });

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apiService = ApiService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUpper => RegExp(r'[A-Z]').hasMatch(_passwordController.text);
  bool get _hasLower => RegExp(r'[a-z]').hasMatch(_passwordController.text);
  bool get _hasUpperLower => _hasUpper && _hasLower;
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_passwordController.text);
  bool get _hasSpecial => RegExp(r'[^a-zA-Z0-9]').hasMatch(_passwordController.text);

  bool get _isPasswordStrong =>
      _hasMinLength && _hasUpperLower && _hasNumber && _hasSpecial;

  int get _passwordStrengthScore {
    final text = _passwordController.text;
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
      setState(() =>
          _errorMessage = AppLocalizations.of(context)!.passMustBeStrong);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.changePassword(
        encNim: widget.encNim,
        email: widget.email,
        otp: widget.otp,
        newPassword: _passwordController.text.trim(),
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
          setState(() => _errorMessage = AppLocalizations.of(context)!.updatePasswordFailed);
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
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
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
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(l10n.goToLoginPage, style: const TextStyle(fontWeight: FontWeight.bold)),
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.vpn_key_rounded, color: Colors.white, size: 60),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Column(
                      children: [
                        Text(
                          l10n.newPassword.toUpperCase(),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.newPassword, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 12),
                          Text(l10n.changePassInstruction, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
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
                          _buildTextField(
                            controller: _passwordController,
                            label: l10n.newPassword.toUpperCase(),
                            hint: l10n.enterNewPassword,
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                            validator: (value) {
                              if (value == null || value.isEmpty) return l10n.newPassRequired;
                              if (value.length < 8) return l10n.passMinLength;
                              if (!RegExp(r'[a-z]').hasMatch(value) || !RegExp(r'[A-Z]').hasMatch(value)) {
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
                          _buildPasswordStrengthSection(l10n),
                          const SizedBox(height: 24),
                          _buildTextField(
                            controller: _confirmPasswordController,
                            label: l10n.confirmPassword.toUpperCase(),
                            hint: l10n.confirmNewPasswordHint,
                            icon: Icons.lock_clock_outlined,
                            isPassword: true,
                            obscureText: _obscureConfirmPassword,
                            onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            validator: (value) {
                              if (value == null || value.isEmpty) return l10n.confPassRequired;
                              if (value != _passwordController.text) return l10n.passNotMatch;
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleChangePassword,
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), elevation: 0),
                              child: _isLoading ? const SpinKitThreeBounce(color: Colors.white, size: 20) : Text(l10n.savePassword.toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStrengthSection(AppLocalizations l10n) {
    final text = _passwordController.text;
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
        // Top status row
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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

        // 3-Segment Progress Bar (Lemah = 1, Sedang = 2, Kuat = 3)
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
          isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
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
              color: isMet ? const Color(0xFF1E293B) : const Color(0xFF64748B),
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
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1),
          ),
        ),
        TextFormField(
          controller: controller,
          enabled: !_isLoading,
          obscureText: isPassword && obscureText,
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.normal),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
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
              borderSide: const BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
