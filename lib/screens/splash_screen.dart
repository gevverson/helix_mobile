import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_constants.dart';
import '../routes/app_router.dart';
import '../services/auth_service.dart';
import '../widgets/animated_dna_logo.dart';

/// Animated splash screen that checks auth state and routes accordingly.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final isLoggedIn = await AuthService.isLoggedIn();
    if (!mounted) return;

    if (!isLoggedIn) {
      context.go(AppRouter.login);
      return;
    }

    // A logged-in user who hasn't consented yet (e.g. a Google sign-in that was
    // interrupted before the gate) is routed to the consent screen first.
    final needsConsent = await AuthService.needsConsent();
    if (!mounted) return;
    context.go(needsConsent ? AppRouter.consent : AppRouter.mainShell);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppConstants.bgGradient),
        child: Center(
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, _) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // DNA Logo
                      const AnimatedDnaLogo(size: 100),
                      const SizedBox(height: 32),

                      // App name
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

                      // Tagline
                      Text(
                        'Your Genetic Health Companion',
                        style: TextStyle(
                          color: AppConstants.textSecondary.withValues(alpha: 0.7),
                          fontSize: 14,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Loading indicator
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppConstants.accentCyan.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
