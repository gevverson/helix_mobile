import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../config/app_constants.dart';
import '../models/match_result.dart';
import '../models/user.dart';
import '../services/profile_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/helix_button.dart';

/// Genetic compatibility checker screen.
///
/// The authenticated user's profile is loaded from the database — they only
/// need to enter the partner's genotype and (optionally) rhesus factor.
class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  User? _userProfile;
  bool _isLoadingProfile = true;

  String _partnerGenotype = '';
  String? _partnerRhesus;
  String _userSex = 'male';

  bool _isChecking = false;
  MatchResult? _result;
  String? _errorMessage;

  static const _genotypes = ['AA', 'AS', 'SS', 'AC', 'SC'];
  static const _rhesusOptions = ['POS', 'NEG'];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await ProfileService.fetchProfile();
    if (mounted) {
      setState(() {
        _userProfile = profile;
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _checkMatch() async {
    if (_partnerGenotype.isEmpty) {
      setState(() => _errorMessage = 'Please select the partner\'s genotype.');
      return;
    }

    final myGenotype = _userProfile?.genotype;
    if (myGenotype == null) {
      setState(() => _errorMessage =
          'Your genotype is not set. Update your profile first.');
      return;
    }

    setState(() {
      _isChecking = true;
      _result = null;
      _errorMessage = null;
    });

    try {
      final result = await ProfileService.checkMatch(
        userSex: _userSex,
        partnerProfile: {
          'genotype': _partnerGenotype,
          if (_partnerRhesus != null) 'rhesus_factor': _partnerRhesus,
        },
      );
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'safe':
        return AppConstants.successColor;
      case 'caution':
        return AppConstants.warningColor;
      case 'danger':
        return AppConstants.errorColor;
      default:
        return AppConstants.accentBlue;
    }
  }

  double _statusPercent(String? status) {
    switch (status) {
      case 'safe':
        return 0.9;
      case 'caution':
        return 0.6;
      case 'danger':
        return 0.2;
      default:
        return 0.5;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppConstants.bgGradient),
        child: SafeArea(
          child: _isLoadingProfile
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // ── Header ──
                    const Text(
                      'Compatibility',
                      style: TextStyle(
                        color: AppConstants.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Compare genotypes to assess genetic compatibility',
                      style: TextStyle(
                        color: AppConstants.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Your Profile (read-only from DB) ──
                    _buildMyProfileCard(),
                    const SizedBox(height: 16),

                    // ── Sex selector for Rh check ──
                    _buildSexSelector(),
                    const SizedBox(height: 16),

                    // ── Partner Profile ──
                    _buildPartnerCard(),
                    const SizedBox(height: 24),

                    // ── Check Button ──
                    HelixButton(
                      label: 'CHECK COMPATIBILITY',
                      icon: Icons.favorite,
                      isLoading: _isChecking,
                      onPressed: _checkMatch,
                      gradient: AppConstants.purpleGradient,
                    ),
                    const SizedBox(height: 24),

                    // ── Error ──
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppConstants.errorColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                AppConstants.errorColor.withValues(alpha: 0.3),
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
                                    color: AppConstants.errorColor,
                                    fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Result ──
                    if (_result != null) _buildResultCard(),

                    // ── Educational Info ──
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppConstants.accentPurple.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              AppConstants.accentPurple.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.school_outlined,
                                color: AppConstants.accentPurple
                                    .withValues(alpha: 0.7),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Did You Know?',
                                style: TextStyle(
                                  color: AppConstants.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'When both partners carry the sickle cell trait (AS), there is a 25% chance their child will have sickle cell disease (SS). Knowing your genotype before marriage can help prevent genetic disorders.',
                            style: TextStyle(
                              color: AppConstants.textSecondary,
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildMyProfileCard() {
    final genotype = _userProfile?.genotype;
    final rhesus = _userProfile?.rhesus;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppConstants.accentGradient.createShader(bounds),
                child: const Icon(Icons.person, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 8),
              const Text(
                'Your Profile',
                style: TextStyle(
                  color: AppConstants.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const Text(
                'from your account',
                style: TextStyle(
                  color: AppConstants.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (genotype == null)
            const Text(
              'Genotype not set — update your profile in the Profile tab before checking compatibility.',
              style: TextStyle(color: AppConstants.warningColor, fontSize: 13),
            )
          else
            Row(
              children: [
                _pill('Genotype: $genotype', AppConstants.accentGradient),
                const SizedBox(width: 8),
                if (rhesus != null)
                  _pill('Rh: $rhesus', AppConstants.purpleGradient),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSexSelector() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          const Text(
            'Your role in Rh check:',
            style: TextStyle(color: AppConstants.textSecondary, fontSize: 13),
          ),
          const SizedBox(width: 12),
          _sexToggle('Male', 'male', AppConstants.accentGradient),
          const SizedBox(width: 8),
          _sexToggle('Female', 'female', AppConstants.purpleGradient),
        ],
      ),
    );
  }

  Widget _sexToggle(String label, String value, LinearGradient gradient) {
    final selected = _userSex == value;
    return GestureDetector(
      onTap: () => setState(() => _userSex = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? gradient : null,
          color: selected ? null : AppConstants.bgPrimary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Colors.transparent : AppConstants.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                selected ? AppConstants.bgPrimary : AppConstants.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPartnerCard() {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppConstants.purpleGradient.createShader(bounds),
                child: const Icon(Icons.people, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 8),
              const Text(
                'Partner\'s Profile',
                style: TextStyle(
                  color: AppConstants.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text(
            'Genotype',
            style:
                TextStyle(color: AppConstants.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _genotypes.map((g) {
              final selected = _partnerGenotype == g;
              return GestureDetector(
                onTap: () => setState(() => _partnerGenotype = g),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: selected ? AppConstants.purpleGradient : null,
                    color: selected ? null : AppConstants.bgPrimary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : AppConstants.borderColor,
                    ),
                  ),
                  child: Text(
                    g,
                    style: TextStyle(
                      color: selected
                          ? AppConstants.bgPrimary
                          : AppConstants.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          const Text(
            'Rhesus Factor (optional)',
            style:
                TextStyle(color: AppConstants.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _rhesusOptions.map((rh) {
              final selected = _partnerRhesus == rh;
              return GestureDetector(
                onTap: () => setState(() =>
                    _partnerRhesus = selected ? null : rh),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: selected ? AppConstants.purpleGradient : null,
                    color: selected ? null : AppConstants.bgPrimary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : AppConstants.borderColor,
                    ),
                  ),
                  child: Text(
                    rh,
                    style: TextStyle(
                      color: selected
                          ? AppConstants.bgPrimary
                          : AppConstants.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final status = _result?.status ?? 'unknown';
    final messages = _result?.messages ?? [];
    final riskColor = _statusColor(status);
    final riskPercent = _statusPercent(status);

    return GlassCard(
      borderColor: riskColor.withValues(alpha: 0.4),
      child: Column(
        children: [
          CircularPercentIndicator(
            radius: 60,
            lineWidth: 8,
            percent: riskPercent,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  riskPercent > 0.5
                      ? Icons.check_circle
                      : Icons.warning_amber_rounded,
                  color: riskColor,
                  size: 28,
                ),
                const SizedBox(height: 4),
                Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: riskColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            progressColor: riskColor,
            backgroundColor: riskColor.withValues(alpha: 0.15),
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(height: 20),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: riskColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...messages.map(
            (msg) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                msg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, LinearGradient gradient) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(bounds),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
