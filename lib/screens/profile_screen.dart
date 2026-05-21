import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/app_constants.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../routes/app_router.dart';
import '../services/profile_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/helix_button.dart';

/// User profile and settings screen.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  User? _user;
  bool _isLoading = true;
  bool _isSaving = false;

  static const _genotypes = ['AA', 'AS', 'SS', 'AC', 'SC'];
  static const _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
  static const _rhesus = ['POS', 'NEG'];

  Future<void> _showEditProfileSheet() async {
    String? selectedGenotype = _user?.genotype;
    String? selectedBloodGroup = _user?.bloodGroup;
    String? selectedRhesus = _user?.rhesus;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppConstants.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppConstants.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Edit Health Data',
                style: TextStyle(color: AppConstants.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),

              // Genotype
              const Text('Genotype', style: TextStyle(color: AppConstants.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _genotypes.map((g) {
                  final selected = g == selectedGenotype;
                  return GestureDetector(
                    onTap: () => setSheetState(() => selectedGenotype = g),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: selected ? AppConstants.purpleGradient : null,
                        color: selected ? null : AppConstants.bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? Colors.transparent : AppConstants.borderColor,
                        ),
                      ),
                      child: Text(g, style: TextStyle(
                        color: selected ? Colors.white : AppConstants.textPrimary,
                        fontWeight: FontWeight.w600,
                      )),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Blood Group
              const Text('Blood Group', style: TextStyle(color: AppConstants.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _bloodGroups.map((b) {
                  final selected = b == selectedBloodGroup;
                  return GestureDetector(
                    onTap: () => setSheetState(() => selectedBloodGroup = b),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: selected ? AppConstants.accentGradient : null,
                        color: selected ? null : AppConstants.bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? Colors.transparent : AppConstants.borderColor,
                        ),
                      ),
                      child: Text(b, style: TextStyle(
                        color: selected ? AppConstants.bgPrimary : AppConstants.textPrimary,
                        fontWeight: FontWeight.w600,
                      )),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Rhesus
              const Text('Rhesus Factor (optional)', style: TextStyle(color: AppConstants.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _rhesus.map((r) {
                  final selected = r == selectedRhesus;
                  return GestureDetector(
                    onTap: () => setSheetState(() => selectedRhesus = selected ? null : r),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? AppConstants.accentCyan.withValues(alpha: 0.2) : AppConstants.bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? AppConstants.accentCyan : AppConstants.borderColor,
                        ),
                      ),
                      child: Text(r, style: TextStyle(
                        color: selected ? AppConstants.accentCyan : AppConstants.textPrimary,
                        fontWeight: FontWeight.w600,
                      )),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppConstants.accentGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton(
                    onPressed: (selectedGenotype == null && selectedBloodGroup == null)
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            setState(() => _isSaving = true);
                            final ok = await ProfileService.updateProfile(
                              selectedGenotype ?? _user?.genotype ?? '',
                              selectedBloodGroup ?? _user?.bloodGroup ?? '',
                            );
                            if (ok && mounted) {
                              await _loadProfile();
                            }
                            if (!mounted) return;
                            setState(() => _isSaving = false);
                            if (ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Profile updated successfully'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: AppConstants.successColor,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: AppConstants.bgPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('SAVE', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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
  void initState() {
    super.initState();
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
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign Out',
          style: TextStyle(color: AppConstants.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppConstants.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out',
                style: TextStyle(color: AppConstants.errorColor)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final router = GoRouter.of(context);
      await context.read<AuthProvider>().logout();
      router.go(AppRouter.login);
    }
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
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  color: AppConstants.accentCyan,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const SizedBox(height: 10),

                      // ── Avatar + Name ──
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                gradient: AppConstants.accentGradient,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppConstants.accentCyan
                                        .withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  (_user?.fullName?.isNotEmpty == true)
                                      ? _user!.fullName![0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: AppConstants.bgPrimary,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _user?.fullName ?? 'Unknown User',
                              style: const TextStyle(
                                color: AppConstants.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _user?.email ?? '',
                              style: const TextStyle(
                                color: AppConstants.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Health Data ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Health Data',
                            style: TextStyle(
                              color: AppConstants.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (_isSaving)
                            const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppConstants.accentCyan,
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: _showEditProfileSheet,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppConstants.accentCyan.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppConstants.accentCyan.withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit_outlined, color: AppConstants.accentCyan, size: 14),
                                    SizedBox(width: 4),
                                    Text('Edit', style: TextStyle(color: AppConstants.accentCyan, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      GlassCard(
                        padding: const EdgeInsets.all(0),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              icon: Icons.biotech,
                              label: 'Genotype',
                              value: _user?.genotype ?? 'Not set',
                              gradient: AppConstants.purpleGradient,
                            ),
                            Divider(
                              color: AppConstants.borderColor.withValues(alpha: 0.3),
                              height: 1,
                            ),
                            _buildInfoRow(
                              icon: Icons.bloodtype,
                              label: 'Blood Group',
                              value: _user?.bloodGroup ?? 'Not set',
                              gradient: AppConstants.accentGradient,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Settings ──
                      const Text(
                        'Settings',
                        style: TextStyle(
                          color: AppConstants.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),

                      _buildSettingsTile(
                        icon: Icons.dark_mode_outlined,
                        title: 'Dark Mode',
                        subtitle: 'Always on',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppConstants.accentCyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              color: AppConstants.accentCyan,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      _buildSettingsTile(
                        icon: Icons.security_outlined,
                        title: 'Privacy & Security',
                        subtitle: 'Manage your data',
                      ),
                      _buildSettingsTile(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        subtitle: 'FAQ and contact us',
                      ),
                      const SizedBox(height: 24),

                      // ── Logout ──
                      HelixButton(
                        label: 'SIGN OUT',
                        icon: Icons.logout,
                        onPressed: _handleLogout,
                        backgroundColor: AppConstants.errorColor,
                        foregroundColor: Colors.white,
                        gradient: null,
                      ),
                      const SizedBox(height: 24),

                      // ── Version ──
                      Center(
                        child: Text(
                          'Helix v${AppConstants.appVersion}',
                          style: const TextStyle(
                            color: AppConstants.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required LinearGradient gradient,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => gradient.createShader(bounds),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: value == 'Not set'
                  ? AppConstants.textMuted
                  : AppConstants.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(icon, color: AppConstants.textSecondary, size: 22),
        title: Text(
          title,
          style: const TextStyle(
            color: AppConstants.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppConstants.textMuted,
            fontSize: 12,
          ),
        ),
        trailing: trailing ??
            const Icon(Icons.arrow_forward_ios,
                color: AppConstants.textMuted, size: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
