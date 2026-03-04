import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../config/app_constants.dart';
import '../services/profile_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/helix_button.dart';

/// Genetic compatibility checker screen.
class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  final _maleGenotypeController = TextEditingController();
  final _maleBloodGroupController = TextEditingController();
  final _femaleGenotypeController = TextEditingController();
  final _femaleBloodGroupController = TextEditingController();

  bool _isChecking = false;
  Map<String, dynamic>? _result;
  String? _errorMessage;

  final _genotypes = ['AA', 'AS', 'SS', 'AC', 'SC'];
  final _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void dispose() {
    _maleGenotypeController.dispose();
    _maleBloodGroupController.dispose();
    _femaleGenotypeController.dispose();
    _femaleBloodGroupController.dispose();
    super.dispose();
  }

  Future<void> _checkMatch() async {
    if (_maleGenotypeController.text.isEmpty ||
        _femaleGenotypeController.text.isEmpty) {
      setState(
          () => _errorMessage = 'Please fill in at least the genotype fields.');
      return;
    }

    setState(() {
      _isChecking = true;
      _result = null;
      _errorMessage = null;
    });

    try {
      final result = await ProfileService.checkMatch(
        {
          'genotype': _maleGenotypeController.text.trim().toUpperCase(),
          'blood_group': _maleBloodGroupController.text.trim().toUpperCase(),
        },
        {
          'genotype': _femaleGenotypeController.text.trim().toUpperCase(),
          'blood_group': _femaleBloodGroupController.text.trim().toUpperCase(),
        },
      );
      setState(() => _result = result);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to check compatibility: $e');
    } finally {
      setState(() => _isChecking = false);
    }
  }

  Color _getRiskColor(String? risk) {
    switch (risk?.toLowerCase()) {
      case 'low':
      case 'safe':
      case 'compatible':
        return AppConstants.successColor;
      case 'medium':
      case 'moderate':
        return AppConstants.warningColor;
      case 'high':
      case 'dangerous':
      case 'incompatible':
        return AppConstants.errorColor;
      default:
        return AppConstants.accentBlue;
    }
  }

  double _getRiskPercent(String? risk) {
    switch (risk?.toLowerCase()) {
      case 'low':
      case 'safe':
      case 'compatible':
        return 0.9;
      case 'medium':
      case 'moderate':
        return 0.6;
      case 'high':
      case 'dangerous':
      case 'incompatible':
        return 0.25;
      default:
        return 0.5;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppConstants.bgGradient),
        child: SafeArea(
          child: ListView(
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

              // ── Male Profile ──
              _buildProfileCard(
                title: 'Partner A',
                icon: Icons.male,
                gradient: AppConstants.accentGradient,
                genotypeController: _maleGenotypeController,
                bloodGroupController: _maleBloodGroupController,
              ),
              const SizedBox(height: 16),

              // ── Female Profile ──
              _buildProfileCard(
                title: 'Partner B',
                icon: Icons.female,
                gradient: AppConstants.purpleGradient,
                genotypeController: _femaleGenotypeController,
                bloodGroupController: _femaleBloodGroupController,
              ),
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
                    color: AppConstants.accentPurple.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.school_outlined,
                            color: AppConstants.accentPurple.withValues(alpha: 0.7),
                            size: 20),
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

  Widget _buildProfileCard({
    required String title,
    required IconData icon,
    required LinearGradient gradient,
    required TextEditingController genotypeController,
    required TextEditingController bloodGroupController,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => gradient.createShader(bounds),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppConstants.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Genotype chips
          const Text(
            'Genotype',
            style: TextStyle(color: AppConstants.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _genotypes.map((g) {
              final selected = genotypeController.text == g;
              return GestureDetector(
                onTap: () => setState(() => genotypeController.text = g),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: selected ? gradient : null,
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

          // Blood group chips
          const Text(
            'Blood Group (optional)',
            style: TextStyle(color: AppConstants.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _bloodGroups.map((bg) {
              final selected = bloodGroupController.text == bg;
              return GestureDetector(
                onTap: () => setState(() => bloodGroupController.text = bg),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: selected ? gradient : null,
                    color: selected ? null : AppConstants.bgPrimary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : AppConstants.borderColor,
                    ),
                  ),
                  child: Text(
                    bg,
                    style: TextStyle(
                      color: selected
                          ? AppConstants.bgPrimary
                          : AppConstants.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
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
    final risk = _result?['risk_level']?.toString() ?? 'Unknown';
    final message = _result?['message']?.toString() ?? 'No details available.';
    final compatibility =
        _result?['compatibility']?.toString() ?? risk;
    final riskColor = _getRiskColor(risk);
    final riskPercent = _getRiskPercent(risk);

    return GlassCard(
      borderColor: riskColor.withValues(alpha: 0.4),
      child: Column(
        children: [
          // ── Gauge ──
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
                  compatibility,
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

          // ── Risk Level ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Risk: $risk',
              style: TextStyle(
                color: riskColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Message ──
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
