import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../config/app_constants.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../routes/app_router.dart';
import '../services/profile_service.dart';
import 'blocked_users_screen.dart';
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
  bool _isDeleting = false;
  List<Map<String, dynamic>> _photos = [];
  bool _photoBusy = false;

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
                              rhesus: selectedRhesus,
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

  static String _cap(String? s) =>
      (s == null || s.isEmpty) ? 'Not set' : s[0].toUpperCase() + s.substring(1);

  static String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _showEditDatingProfileSheet() async {
    DateTime? dob = (_user?.dateOfBirth != null)
        ? DateTime.tryParse(_user!.dateOfBirth!)
        : null;
    String? gender = _user?.gender;
    String? seeking = _user?.seeking;
    final bioController = TextEditingController(text: _user?.bio ?? '');
    final cityController = TextEditingController(text: _user?.city ?? '');

    Widget chip(String value, String label, String? selectedVal, VoidCallback onTap,
        {LinearGradient? gradient}) {
      final selected = value == selectedVal;
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            gradient: selected ? (gradient ?? AppConstants.accentGradient) : null,
            color: selected ? null : AppConstants.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? Colors.transparent : AppConstants.borderColor,
            ),
          ),
          child: Text(label,
              style: TextStyle(
                color: selected ? AppConstants.bgPrimary : AppConstants.textPrimary,
                fontWeight: FontWeight.w600,
              )),
        ),
      );
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppConstants.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppConstants.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Edit Dating Profile',
                  style: TextStyle(
                      color: AppConstants.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),

              const Text('Date of Birth',
                  style: TextStyle(color: AppConstants.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: dob ?? DateTime(now.year - 25, now.month, now.day),
                    firstDate: DateTime(now.year - 100),
                    lastDate: DateTime(now.year - 18, now.month, now.day),
                  );
                  if (picked != null) setSheet(() => dob = picked);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  decoration: BoxDecoration(
                    color: AppConstants.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppConstants.borderColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cake_outlined, color: AppConstants.textSecondary, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        dob != null ? _fmtDate(dob!) : 'Select your date of birth (18+)',
                        style: TextStyle(
                          color: dob != null ? AppConstants.textPrimary : AppConstants.textMuted,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text('I am',
                  style: TextStyle(color: AppConstants.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                chip('male', 'Male', gender, () => setSheet(() => gender = 'male'), gradient: AppConstants.accentGradient),
                chip('female', 'Female', gender, () => setSheet(() => gender = 'female'), gradient: AppConstants.purpleGradient),
                chip('other', 'Other', gender, () => setSheet(() => gender = 'other')),
              ]),
              const SizedBox(height: 20),

              const Text('Looking for',
                  style: TextStyle(color: AppConstants.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                chip('male', 'Men', seeking, () => setSheet(() => seeking = 'male'), gradient: AppConstants.accentGradient),
                chip('female', 'Women', seeking, () => setSheet(() => seeking = 'female'), gradient: AppConstants.purpleGradient),
                chip('everyone', 'Everyone', seeking, () => setSheet(() => seeking = 'everyone')),
              ]),
              const SizedBox(height: 20),

              const Text('About me',
                  style: TextStyle(color: AppConstants.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              TextField(
                controller: bioController,
                maxLength: 300,
                maxLines: 3,
                style: const TextStyle(color: AppConstants.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Say something about yourself…',
                ),
              ),
              const SizedBox(height: 8),

              const Text('City (optional)',
                  style: TextStyle(color: AppConstants.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              const Text('Coarse location for distance filtering — no GPS is used.',
                  style: TextStyle(color: AppConstants.textMuted, fontSize: 11.5)),
              const SizedBox(height: 10),
              TextField(
                controller: cityController,
                maxLength: 100,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(color: AppConstants.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'e.g. Nairobi',
                  prefixIcon: Icon(Icons.place_outlined, color: AppConstants.textSecondary, size: 18),
                ),
              ),
              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppConstants.accentGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton(
                    onPressed: (dob == null || gender == null || seeking == null)
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            setState(() => _isSaving = true);
                            final ok = await ProfileService.updateDatingProfile(
                              dateOfBirth: _fmtDate(dob!),
                              gender: gender!,
                              seeking: seeking!,
                              bio: bioController.text.trim(),
                              city: cityController.text.trim(),
                            );
                            if (ok && mounted) await _loadProfile();
                            if (!mounted) return;
                            setState(() => _isSaving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok
                                    ? 'Dating profile saved'
                                    : 'Could not save. Please try again.'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: ok
                                    ? AppConstants.successColor
                                    : AppConstants.errorColor,
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: AppConstants.bgPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('SAVE',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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
      final photos = await ProfileService.fetchPhotos();
      if (mounted) {
        setState(() {
          _user = user;
          _photos = photos;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addPhoto() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;

    setState(() => _photoBusy = true);
    final bytes = await file.readAsBytes();
    final url = await ProfileService.uploadPhoto(bytes, file.name, mimeType: file.mimeType);
    if (!mounted) return;

    if (url != null) {
      await _loadProfile();
      if (mounted) setState(() => _photoBusy = false);
    } else {
      setState(() => _photoBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not upload photo. Please try again.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  Future<void> _deletePhoto(String id) async {
    setState(() => _photoBusy = true);
    final ok = await ProfileService.deletePhoto(id);
    if (ok && mounted) await _loadProfile();
    if (mounted) setState(() => _photoBusy = false);
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

  Future<void> _handleDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Account',
          style: TextStyle(color: AppConstants.textPrimary),
        ),
        content: const Text(
          'This permanently erases your account and all your health data — '
          'genotype, blood group, and rhesus factor. This cannot be undone.',
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
            child: const Text('Delete Forever',
                style: TextStyle(color: AppConstants.errorColor)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isDeleting = true);
    final ok = await ProfileService.deleteAccount();
    if (!mounted) return;

    if (ok) {
      final router = GoRouter.of(context);
      await context.read<AuthProvider>().logout();
      router.go(AppRouter.login);
    } else {
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete account. Please try again.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppConstants.errorColor,
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
                      const SizedBox(height: 28),

                      // ── Photos ──
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Photos',
                          style: TextStyle(
                            color: AppConstants.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 108,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final p in _photos) _photoThumb(p),
                            _addPhotoTile(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

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
                            Divider(
                              color: AppConstants.borderColor.withValues(alpha: 0.3),
                              height: 1,
                            ),
                            _buildInfoRow(
                              icon: Icons.science_outlined,
                              label: 'Rhesus Factor',
                              value: _user?.rhesus != null
                                  ? 'Rh ${_user!.rhesus}'
                                  : 'Not set',
                              gradient: AppConstants.purpleGradient,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Dating Profile ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Dating Profile',
                            style: TextStyle(
                              color: AppConstants.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          GestureDetector(
                            onTap: _showEditDatingProfileSheet,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppConstants.accentPurple.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppConstants.accentPurple.withValues(alpha: 0.35)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit_outlined, color: AppConstants.accentPurple, size: 14),
                                  SizedBox(width: 4),
                                  Text('Edit', style: TextStyle(color: AppConstants.accentPurple, fontSize: 12, fontWeight: FontWeight.w600)),
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
                              icon: Icons.cake_outlined,
                              label: 'Age',
                              value: _user?.age?.toString() ?? 'Not set',
                              gradient: AppConstants.accentGradient,
                            ),
                            Divider(color: AppConstants.borderColor.withValues(alpha: 0.3), height: 1),
                            _buildInfoRow(
                              icon: Icons.person_outline,
                              label: 'Gender',
                              value: _cap(_user?.gender),
                              gradient: AppConstants.purpleGradient,
                            ),
                            Divider(color: AppConstants.borderColor.withValues(alpha: 0.3), height: 1),
                            _buildInfoRow(
                              icon: Icons.favorite_border,
                              label: 'Looking for',
                              value: _cap(_user?.seeking),
                              gradient: AppConstants.accentGradient,
                            ),
                          ],
                        ),
                      ),
                      if (_user?.bio != null && _user!.bio!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppConstants.bgCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppConstants.borderColor),
                          ),
                          child: Text(
                            _user!.bio!,
                            style: const TextStyle(color: AppConstants.textSecondary, fontSize: 14, height: 1.5),
                          ),
                        ),
                      ],
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
                        icon: Icons.block_outlined,
                        title: 'Blocked Users',
                        subtitle: 'Manage who you\'ve blocked',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BlockedUsersScreen()),
                        ),
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
                      const SizedBox(height: 8),

                      // ── Delete Account (right to erasure) ──
                      Center(
                        child: _isDeleting
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppConstants.errorColor,
                                  ),
                                ),
                              )
                            : TextButton.icon(
                                onPressed: _handleDeleteAccount,
                                icon: const Icon(Icons.delete_forever_outlined,
                                    color: AppConstants.errorColor, size: 18),
                                label: const Text(
                                  'Delete My Account',
                                  style: TextStyle(
                                    color: AppConstants.errorColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),

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

  Widget _photoThumb(Map<String, dynamic> p) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              p['url'] as String,
              width: 100,
              height: 108,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 100,
                height: 108,
                color: AppConstants.bgCard,
                child: const Icon(Icons.broken_image_outlined, color: AppConstants.textMuted),
              ),
              loadingBuilder: (c, child, prog) => prog == null
                  ? child
                  : Container(
                      width: 100,
                      height: 108,
                      color: AppConstants.bgCard,
                      child: const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.accentCyan),
                        ),
                      ),
                    ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: _photoBusy ? null : () => _deletePhoto(p['id'] as String),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
          if ((p['is_primary'] as bool?) ?? false)
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppConstants.accentCyan,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Main',
                    style: TextStyle(color: AppConstants.bgPrimary, fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _addPhotoTile() {
    return GestureDetector(
      onTap: _photoBusy ? null : _addPhoto,
      child: Container(
        width: 100,
        height: 108,
        decoration: BoxDecoration(
          color: AppConstants.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppConstants.borderColor),
        ),
        child: Center(
          child: _photoBusy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.accentCyan),
                )
              : const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_a_photo_outlined, color: AppConstants.accentCyan, size: 22),
                    SizedBox(height: 4),
                    Text('Add', style: TextStyle(color: AppConstants.textSecondary, fontSize: 12)),
                  ],
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
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: ListTile(
        onTap: onTap,
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
