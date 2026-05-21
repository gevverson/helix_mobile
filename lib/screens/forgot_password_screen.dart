import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../config/app_constants.dart';
import '../routes/app_router.dart';
import '../widgets/glass_card.dart';
import '../widgets/helix_button.dart';
import '../widgets/helix_text_field.dart';

/// Two-step password reset screen.
///
/// Step 1 — enter email → backend generates a 6-digit code.
/// Step 2 — enter the code + new password → backend verifies and resets.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AnimationController _animController;
  late Animation<double> _fadeIn;

  bool _isLoading = false;
  bool _codeSent = false;
  String? _demoCode;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter your email address.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/v1/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailController.text.trim()}),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _codeSent = true;
          _demoCode = body['demo_code'] as String?;
          _errorMessage = null;
        });
        _animController.forward(from: 0);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Network error. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/v1/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'code': _codeController.text.trim(),
          'new_password': _passwordController.text,
        }),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() => _successMessage = body['message'] as String?);
        }
      } else {
        if (mounted) {
          setState(() => _errorMessage = body['detail'] as String? ?? 'Reset failed.');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Network error. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppConstants.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: FadeTransition(
              opacity: _fadeIn,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Back ──
                  IconButton(
                    onPressed: () => context.go(AppRouter.login),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: AppConstants.textSecondary,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: 28),

                  // ── Icon ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppConstants.accentCyan.withValues(alpha: 0.1),
                      border: Border.all(
                        color: AppConstants.accentCyan.withValues(alpha: 0.3),
                      ),
                    ),
                    child: ShaderMask(
                      shaderCallback: (bounds) =>
                          AppConstants.accentGradient.createShader(bounds),
                      child: const Icon(
                        Icons.lock_reset,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Reset Password',
                    style: TextStyle(
                      color: AppConstants.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _codeSent
                        ? 'Enter the 6-digit code and your new password.'
                        : 'Enter your email and we\'ll generate a reset code.',
                    style: const TextStyle(
                      color: AppConstants.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Success ──
                  if (_successMessage != null) ...[
                    GlassCard(
                      borderColor: AppConstants.successColor.withValues(alpha: 0.4),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle,
                              color: AppConstants.successColor, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            _successMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppConstants.textPrimary,
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          HelixButton(
                            label: 'SIGN IN',
                            icon: Icons.login,
                            onPressed: () => context.go(AppRouter.login),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[

                    // ── Step 1: Email ──
                    GlassCard(
                      child: Column(
                        children: [
                          HelixTextField(
                            controller: _emailController,
                            label: 'Email Address',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          if (!_codeSent) ...[
                            const SizedBox(height: 20),
                            HelixButton(
                              label: 'SEND RESET CODE',
                              icon: Icons.send_outlined,
                              isLoading: _isLoading,
                              onPressed: _sendCode,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // ── Demo code banner (replaces email in demo) ──
                    if (_codeSent && _demoCode != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppConstants.accentPurple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppConstants.accentPurple.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppConstants.accentPurple.withValues(alpha: 0.8),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Demo Mode',
                                    style: TextStyle(
                                      color: AppConstants.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'In production this code would arrive by email. Your code:',
                                    style: TextStyle(
                                      color: AppConstants.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _demoCode!,
                                    style: TextStyle(
                                      color: AppConstants.accentCyan,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ── Step 2: Code + New Password ──
                    if (_codeSent) ...[
                      const SizedBox(height: 16),
                      GlassCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              HelixTextField(
                                controller: _codeController,
                                label: '6-Digit Reset Code',
                                prefixIcon: Icons.dialpad,
                                keyboardType: TextInputType.number,
                                validator: (v) => (v == null || v.trim().length != 6)
                                    ? 'Enter the 6-digit code'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              HelixTextField(
                                controller: _passwordController,
                                label: 'New Password',
                                prefixIcon: Icons.lock_outline,
                                obscureText: true,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Enter a new password';
                                  if (v.length < 8) return 'At least 8 characters';
                                  if (!v.contains(RegExp(r'\d'))) return 'Include at least one number';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              HelixTextField(
                                controller: _confirmController,
                                label: 'Confirm Password',
                                prefixIcon: Icons.lock_outline,
                                obscureText: true,
                                validator: (v) => v != _passwordController.text
                                    ? 'Passwords do not match'
                                    : null,
                              ),
                              const SizedBox(height: 24),
                              HelixButton(
                                label: 'RESET PASSWORD',
                                icon: Icons.check,
                                isLoading: _isLoading,
                                onPressed: _resetPassword,
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => setState(() {
                                          _codeSent = false;
                                          _demoCode = null;
                                          _errorMessage = null;
                                        }),
                                child: const Text(
                                  'Send a new code',
                                  style: TextStyle(
                                    color: AppConstants.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // ── Error ──
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppConstants.errorColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppConstants.errorColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppConstants.errorColor, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                    color: AppConstants.errorColor, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
