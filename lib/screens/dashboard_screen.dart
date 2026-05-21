import 'package:flutter/material.dart';
import '../config/app_constants.dart';
import '../models/user.dart';
import '../services/profile_service.dart';
import '../widgets/stat_card.dart';

/// Home/overview screen showing health summary and quick actions.
class DashboardScreen extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateTo;

  const DashboardScreen({super.key, this.onNavigateTo});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  User? _user;
  bool _isLoading = true;
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await ProfileService.fetchProfile();
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
        _animController.forward();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppConstants.bgGradient),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppConstants.accentCyan,
                  ),
                )
              : FadeTransition(
                  opacity: _fadeIn,
                  child: RefreshIndicator(
                    onRefresh: _loadProfile,
                    color: AppConstants.accentCyan,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // ── Greeting ──
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: AppConstants.accentGradient,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  (_user?.fullName?.isNotEmpty == true)
                                      ? _user!.fullName![0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: AppConstants.bgPrimary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back,',
                                    style: TextStyle(
                                      color: AppConstants.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _user?.fullName ?? 'User',
                                    style: const TextStyle(
                                      color: AppConstants.textPrimary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Notification bell placeholder
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppConstants.bgCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppConstants.borderColor),
                              ),
                              child: const Icon(
                                Icons.notifications_outlined,
                                color: AppConstants.textSecondary,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // ── Health Overview ──
                        const Text(
                          'Health Overview',
                          style: TextStyle(
                            color: AppConstants.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                icon: Icons.bloodtype,
                                label: 'BLOOD GROUP',
                                value: _user?.bloodGroup ?? '—',
                                gradient: AppConstants.accentGradient,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: StatCard(
                                icon: Icons.biotech,
                                label: 'GENOTYPE',
                                value: _user?.genotype ?? '—',
                                gradient: AppConstants.purpleGradient,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // ── Quick Actions ──
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            color: AppConstants.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),

                        _buildActionCard(
                          icon: Icons.document_scanner,
                          title: 'Scan Medical Report',
                          subtitle: 'Upload a lab report to extract your genotype & blood group',
                          gradient: AppConstants.accentGradient,
                          onTap: () => widget.onNavigateTo?.call(1),
                        ),
                        const SizedBox(height: 12),

                        _buildActionCard(
                          icon: Icons.favorite,
                          title: 'Check Compatibility',
                          subtitle: 'Compare genotypes to assess genetic compatibility',
                          gradient: AppConstants.purpleGradient,
                          onTap: () => widget.onNavigateTo?.call(2),
                        ),
                        const SizedBox(height: 28),

                        // ── Info Section ──
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppConstants.accentCyan.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppConstants.accentCyan.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppConstants.accentCyan.withValues(alpha: 0.7),
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Know your genotype. It could save lives. Sickle cell disease affects millions worldwide.',
                                  style: TextStyle(
                                    color: AppConstants.textSecondary,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppConstants.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppConstants.borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    gradient.colors.first.withValues(alpha: 0.2),
                    gradient.colors.last.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ShaderMask(
                shaderCallback: (bounds) => gradient.createShader(bounds),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppConstants.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppConstants.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppConstants.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
