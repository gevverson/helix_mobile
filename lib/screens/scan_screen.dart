import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../config/app_constants.dart';
import '../models/scan_result.dart';
import '../services/network_guard.dart';
import '../services/profile_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/helix_button.dart';

/// Dedicated screen for scanning medical reports via OCR.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _isScanning = false;
  bool _isSaving = false;
  ScanResult? _lastScan;
  String? _errorMessage;

  // Cached file so "Try Again" retries without re-opening the picker.
  Uint8List? _cachedBytes;
  String? _cachedFileName;

  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _scanReport() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null) return;

    final pickedFile = result.files.first;
    final bytes = pickedFile.bytes ??
        ((!kIsWeb && pickedFile.path != null)
            ? await File(pickedFile.path!).readAsBytes()
            : null);

    if (bytes == null) {
      setState(() => _errorMessage = 'Could not read the selected file.');
      return;
    }

    _cachedBytes = bytes;
    _cachedFileName = pickedFile.name;
    await _runScan(bytes, pickedFile.name);
  }

  Future<void> _retryWithCachedFile() async {
    if (_cachedBytes == null || _cachedFileName == null) {
      // Cache cleared — fall back to picker
      await _scanReport();
      return;
    }
    await _runScan(_cachedBytes!, _cachedFileName!);
  }

  Future<void> _runScan(Uint8List fileBytes, String fileName) async {
    setState(() {
      _isScanning = true;
      _lastScan = null;
      _errorMessage = null;
    });

    try {
      final scan = await ProfileService.scanReport(fileBytes, fileName);
      if (mounted) {
        setState(() {
          if (scan != null && scan.hasData) {
            _lastScan = scan;
          } else {
            _errorMessage = 'Could not read the document. Try a clearer image.';
          }
        });
        _animController.forward(from: 0);
      }
    } on NetworkOfflineException catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Upload failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _saveToProfile() async {
    if (_lastScan == null) return;

    setState(() => _isSaving = true);

    final success = await ProfileService.updateProfile(
      _lastScan!.genotype ?? 'Unknown',
      _lastScan!.bloodGroup ?? 'Unknown',
    );

    setState(() {
      _isSaving = false;
      if (success) {
        _lastScan = null;
        _errorMessage = null;
      } else {
        _errorMessage = 'Failed to save. Please try again.';
      }
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: AppConstants.successColor, size: 18),
              SizedBox(width: 8),
              Text('Profile updated successfully!'),
            ],
          ),
          backgroundColor: AppConstants.bgElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppConstants.bgGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Header ──
              const Text(
                'Scan Report',
                style: TextStyle(
                  color: AppConstants.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Upload a medical report to extract health data',
                style: TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 28),

              // ── Upload Area ──
              GestureDetector(
                onTap: _isScanning ? null : _scanReport,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppConstants.bgCard.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isScanning
                          ? AppConstants.accentCyan.withValues(alpha: 0.5)
                          : AppConstants.borderColor,
                      width: _isScanning ? 2 : 1,
                    ),
                  ),
                  child: _isScanning
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: AppConstants.accentCyan.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Analyzing document...',
                              style: TextStyle(
                                color: AppConstants.accentCyan,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppConstants.accentCyan.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: ShaderMask(
                                shaderCallback: (bounds) =>
                                    AppConstants.accentGradient.createShader(bounds),
                                child: const Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Tap to upload medical report',
                              style: TextStyle(
                                color: AppConstants.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Supports images (JPG, PNG)',
                              style: TextStyle(
                                color: AppConstants.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                ),
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
                            color: AppConstants.errorColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Scan Result ──
              if (_lastScan != null)
                FadeTransition(
                  opacity: _fadeIn,
                  child: GlassCard(
                    borderColor: AppConstants.successColor.withValues(alpha: 0.3),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppConstants.successColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                color: AppConstants.successColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Data Detected',
                              style: TextStyle(
                                color: AppConstants.successColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        _buildResultRow(
                          icon: Icons.biotech,
                          label: 'Genotype',
                          value: _lastScan!.genotype ?? 'N/A',
                        ),
                        const SizedBox(height: 14),
                        _buildResultRow(
                          icon: Icons.bloodtype,
                          label: 'Blood Group',
                          value: _lastScan!.bloodGroup ?? 'N/A',
                        ),
                        const SizedBox(height: 24),

                        HelixButton(
                          label: 'SAVE TO PROFILE',
                          icon: Icons.save,
                          isLoading: _isSaving,
                          onPressed: _saveToProfile,
                          backgroundColor: AppConstants.successColor,
                          foregroundColor: AppConstants.bgPrimary,
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Retry buttons ──
              if (_lastScan == null && !_isScanning && _errorMessage != null) ...[
                const SizedBox(height: 8),
                HelixButton(
                  label: _cachedBytes != null ? 'RETRY SAME FILE' : 'TRY AGAIN',
                  icon: Icons.refresh,
                  onPressed: _cachedBytes != null ? _retryWithCachedFile : _scanReport,
                  outlined: true,
                ),
                if (_cachedBytes != null) ...[
                  const SizedBox(height: 10),
                  HelixButton(
                    label: 'CHOOSE DIFFERENT FILE',
                    icon: Icons.upload_file,
                    onPressed: _scanReport,
                    outlined: true,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppConstants.bgPrimary.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppConstants.textSecondary, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppConstants.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
