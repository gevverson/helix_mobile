import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/app_constants.dart';
import '../providers/auth_provider.dart';
import '../routes/app_router.dart';
import '../widgets/helix_button.dart';

/// Consent + 18 gate shown after a Google sign-in (which skips the registration
/// form). A user cannot enter the app until they give the same explicit consents
/// as an email sign-up.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _consentHealth = false;
  bool _consentCrossBorder = false;
  bool _isOver18 = false;
  bool _submitting = false;

  bool get _allConsented => _consentHealth && _consentCrossBorder && _isOver18;

  Future<void> _continue() async {
    if (!_consentHealth || !_consentCrossBorder || !_isOver18) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm you are 18+ and provide both consents.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    final ok = await context.read<AuthProvider>().recordConsent(
          consentHealthData: _consentHealth,
          consentCrossBorder: _consentCrossBorder,
          isOver18: _isOver18,
        );
    if (!mounted) return;

    if (ok) {
      context.go(AppRouter.mainShell);
    } else {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your consent. Please try again.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  Future<void> _cancel() async {
    final router = GoRouter.of(context);
    await context.read<AuthProvider>().logout();
    router.go(AppRouter.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppConstants.bgGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Before you continue',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Helix works with your genetic and health data, so we need your explicit consent.',
                    style: TextStyle(color: AppConstants.textSecondary, fontSize: 14.5, height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  _tile(
                    value: _consentHealth,
                    onChanged: (v) => setState(() => _consentHealth = v),
                    text:
                        'I consent to Helix processing my genetic and health data (genotype, blood group, rhesus) to provide compatibility results.',
                  ),
                  const SizedBox(height: 12),
                  _tile(
                    value: _consentCrossBorder,
                    onChanged: (v) => setState(() => _consentCrossBorder = v),
                    text:
                        'I consent to my data being stored and processed on secure servers located outside Kenya (United States).',
                  ),
                  const SizedBox(height: 12),
                  _tile(
                    value: _isOver18,
                    onChanged: (v) => setState(() => _isOver18 = v),
                    text: 'I confirm that I am at least 18 years old.',
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
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
                  const SizedBox(height: 28),

                  HelixButton(
                    label: 'CONTINUE',
                    icon: Icons.check_circle_outline,
                    isLoading: _submitting,
                    // Greyed out until all three consents are ticked.
                    onPressed: _allConsented ? _continue : null,
                    gradient: AppConstants.accentGradient,
                  ),
                  if (!_allConsented) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Tick all three above to continue.',
                      style: TextStyle(color: AppConstants.textMuted, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _submitting ? null : _cancel,
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppConstants.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile({
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
                fontSize: 13,
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
        title: const Text('Privacy Policy',
            style: TextStyle(color: AppConstants.textPrimary, fontSize: 18)),
        content: const SingleChildScrollView(
          child: Text(
            'Helix handles genetic and health data — among the most sensitive '
            'categories of personal data.\n\n'
            'WHAT WE COLLECT: your name and email; your genotype, blood group, and '
            'rhesus factor; and, if you scan a medical report, the image is read by '
            'OCR and not retained.\n\n'
            'HOW WE USE IT: only to run your compatibility checks and manage your '
            'account. We never sell or share it with advertisers.\n\n'
            'WHERE IT IS STORED: on secure servers in the United States, encrypted '
            'at rest. You consent to this cross-border transfer here.\n\n'
            'YOUR RIGHTS: view and update your data anytime, and permanently delete '
            'your account and all data ("Delete My Account").\n\n'
            'CONTACT: gevversonkipkoech@gmail.com. Kenyan users may also contact the '
            'Office of the Data Protection Commissioner (ODPC).\n\n'
            'Helix is for users aged 18 and over.',
            style: TextStyle(color: AppConstants.textSecondary, fontSize: 13, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppConstants.accentCyan)),
          ),
        ],
      ),
    );
  }
}
