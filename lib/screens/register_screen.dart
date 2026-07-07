import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/app_constants.dart';
import '../providers/auth_provider.dart';
import '../routes/app_router.dart';
import '../widgets/glass_card.dart';
import '../widgets/helix_text_field.dart';
import '../widgets/helix_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  double _passwordStrength = 0;
  bool _consentHealth = false;
  bool _consentCrossBorder = false;
  bool _isOver18 = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    _passwordController.addListener(_updatePasswordStrength);
  }

  void _updatePasswordStrength() {
    final pass = _passwordController.text;
    double strength = 0;
    if (pass.length >= 4) strength += 0.2;
    if (pass.length >= 8) strength += 0.2;
    if (pass.contains(RegExp(r'[A-Z]'))) strength += 0.2;
    if (pass.contains(RegExp(r'[0-9]'))) strength += 0.2;
    if (pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.2;
    setState(() => _passwordStrength = strength);
  }

  Color get _strengthColor {
    if (_passwordStrength <= 0.2) return AppConstants.errorColor;
    if (_passwordStrength <= 0.4) return AppConstants.warningColor;
    if (_passwordStrength <= 0.6) return Colors.orange;
    return AppConstants.successColor;
  }

  String get _strengthLabel {
    if (_passwordStrength <= 0.2) return 'Weak';
    if (_passwordStrength <= 0.4) return 'Fair';
    if (_passwordStrength <= 0.6) return 'Good';
    if (_passwordStrength <= 0.8) return 'Strong';
    return 'Excellent';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_consentHealth || !_consentCrossBorder || !_isOver18) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please confirm you are 18+ and provide both consents to continue.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
      consentHealthData: _consentHealth,
      consentCrossBorder: _consentCrossBorder,
      isOver18: _isOver18,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: AppConstants.successColor, size: 18),
              SizedBox(width: 8),
              Text('Account created! Please sign in.'),
            ],
          ),
          backgroundColor: AppConstants.bgElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      if (context.mounted) context.go(AppRouter.login);
    }
  }

  Widget _buildConsentTile({
    required bool value,
    required ValueChanged<bool> onChanged,
    required String text,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: AppConstants.accentCyan,
              checkColor: AppConstants.bgPrimary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: AppConstants.textPrimary, fontSize: 18),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'Helix handles genetic and health data — among the most sensitive '
            'categories of personal data.\n\n'
            'WHAT WE COLLECT: your name and email; your genotype, blood group, '
            'and rhesus factor; and, if you scan a medical report, the image is '
            'read by OCR and not retained.\n\n'
            'HOW WE USE IT: only to run your compatibility checks and manage your '
            'account. We never sell or share it with advertisers.\n\n'
            'WHERE IT IS STORED: on secure servers in the United States, encrypted '
            'at rest. You consent to this cross-border transfer at sign-up.\n\n'
            'YOUR RIGHTS: view and update your data anytime, and permanently delete '
            'your account and all data from the app ("Delete My Account").\n\n'
            'CONTACT: gevversonkipkoech@gmail.com. Kenyan users may also contact the '
            'Office of the Data Protection Commissioner (ODPC).\n\n'
            'Helix is for users aged 18 and over.',
            style: TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close',
                style: TextStyle(color: AppConstants.accentCyan)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppConstants.bgGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeIn,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Branding ──
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppConstants.accentPurple.withValues(alpha: 0.2),
                            AppConstants.accentCyan.withValues(alpha: 0.1),
                          ],
                        ),
                        border: Border.all(
                          color: AppConstants.accentPurple.withValues(alpha: 0.3),
                        ),
                      ),
                      child: ShaderMask(
                        shaderCallback: (bounds) =>
                            AppConstants.purpleGradient.createShader(bounds),
                        child: const Icon(
                          Icons.person_add_outlined,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Join the Helix network',
                      style: TextStyle(
                        color: AppConstants.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Register Form ──
                    GlassCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            HelixTextField(
                              controller: _nameController,
                              label: 'Full Name',
                              prefixIcon: Icons.person_outline,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Name is required';
                                }
                                if (value.trim().length < 2) {
                                  return 'Name must be at least 2 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            HelixTextField(
                              controller: _emailController,
                              label: 'Email',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Email is required';
                                }
                                final emailRegex =
                                    RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                if (!emailRegex.hasMatch(value.trim())) {
                                  return 'Enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            HelixTextField(
                              controller: _passwordController,
                              label: 'Password',
                              prefixIcon: Icons.lock_outline,
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password is required';
                                }
                                if (value.length < 8) {
                                  return 'Password must be at least 8 characters';
                                }
                                return null;
                              },
                            ),

                            // Password strength indicator
                            if (_passwordController.text.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: _passwordStrength,
                                        backgroundColor:
                                            AppConstants.bgPrimary.withValues(alpha: 0.5),
                                        color: _strengthColor,
                                        minHeight: 4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _strengthLabel,
                                    style: TextStyle(
                                      color: _strengthColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),

                            HelixTextField(
                              controller: _confirmPasswordController,
                              label: 'Confirm Password',
                              prefixIcon: Icons.lock_outline,
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // ── Consent (explicit, granular — no pre-ticking) ──
                            _buildConsentTile(
                              value: _consentHealth,
                              onChanged: (v) =>
                                  setState(() => _consentHealth = v),
                              text:
                                  'I consent to Helix processing my genetic and health data (genotype, blood group, rhesus) to provide compatibility results.',
                            ),
                            const SizedBox(height: 10),
                            _buildConsentTile(
                              value: _consentCrossBorder,
                              onChanged: (v) =>
                                  setState(() => _consentCrossBorder = v),
                              text:
                                  'I consent to my data being stored and processed on secure servers located outside Kenya (United States).',
                            ),
                            const SizedBox(height: 10),
                            _buildConsentTile(
                              value: _isOver18,
                              onChanged: (v) => setState(() => _isOver18 = v),
                              text:
                                  'I confirm that I am at least 18 years old.',
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: GestureDetector(
                                onTap: _showPrivacyPolicy,
                                child: const Text(
                                  'Read our Privacy Policy',
                                  style: TextStyle(
                                    color: AppConstants.accentCyan,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Error message
                            if (authProvider.errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppConstants.errorColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppConstants.errorColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline,
                                        color: AppConstants.errorColor, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        authProvider.errorMessage!,
                                        style: const TextStyle(
                                          color: AppConstants.errorColor,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Register button
                            HelixButton(
                              label: 'CREATE ACCOUNT',
                              icon: Icons.person_add,
                              isLoading: authProvider.isLoading,
                              onPressed: _handleRegister,
                              gradient: AppConstants.purpleGradient,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Login link ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(
                            color: AppConstants.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            authProvider.clearError();
                            context.go(AppRouter.login);
                          },
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: AppConstants.accentCyan,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
