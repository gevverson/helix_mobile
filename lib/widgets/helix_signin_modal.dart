import 'package:flutter/material.dart';
import '../config/app_constants.dart';
import 'animated_dna_logo.dart';

/// Shows a branded Helix modal before triggering Google Sign-In.
///
/// Returns `true` if the user taps "Continue", `false` if dismissed.
Future<bool> showHelixSignInModal(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    transitionAnimationController: AnimationController(
      vsync: Navigator.of(context),
      duration: const Duration(milliseconds: 400),
    ),
    builder: (ctx) => const _HelixSignInModalContent(),
  );
  return result ?? false;
}

class _HelixSignInModalContent extends StatefulWidget {
  const _HelixSignInModalContent();

  @override
  State<_HelixSignInModalContent> createState() =>
      _HelixSignInModalContentState();
}

class _HelixSignInModalContentState extends State<_HelixSignInModalContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
        decoration: BoxDecoration(
          color: AppConstants.bgCard,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppConstants.accentCyan.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppConstants.accentCyan.withValues(alpha: 0.08),
              blurRadius: 40,
              spreadRadius: 0,
              offset: const Offset(0, -8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 30,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag Handle ──
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppConstants.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),

            // ── Helix DNA Logo ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppConstants.accentCyan.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                  radius: 0.8,
                ),
              ),
              child: const AnimatedDnaLogo(size: 80),
            ),
            const SizedBox(height: 24),

            // ── HELIX Brand Text ──
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppConstants.accentGradient.createShader(bounds),
              child: const Text(
                'HELIX',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Tagline ──
            Text(
              'Securing your vault with Google',
              style: TextStyle(
                color: AppConstants.textSecondary.withValues(alpha: 0.9),
                fontSize: 15,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your health data is encrypted end-to-end',
              style: TextStyle(
                color: AppConstants.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 32),

            // ── Continue Button ──
            SizedBox(
              width: double.infinity,
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppConstants.accentGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppConstants.accentCyan.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Image.network(
                    'https://www.gstatic.com/images/branding/product/1x/gsa_512dp.png',
                    width: 22,
                    height: 22,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.shield_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  label: const Text(
                    'Continue with Google',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Cancel ──
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppConstants.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
