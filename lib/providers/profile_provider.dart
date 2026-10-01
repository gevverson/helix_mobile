import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/profile_service.dart';

/// Manages the authenticated user's profile state across the app.
///
/// Load once on login (or on demand) and share across screens via
/// `context.watch<ProfileProvider>()` / `context.read<ProfileProvider>()`.
class ProfileProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasProfile => _user?.genotype != null;

  /// Fetch the current user's profile from the backend and cache it locally.
  Future<void> loadProfile({bool force = false}) async {
    if (_user != null && !force) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await ProfileService.fetchProfile();
      if (_user == null) _errorMessage = 'Failed to load profile.';
    } catch (_) {
      _errorMessage = 'Failed to load profile.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save updated genotype and blood group then refresh the cached profile.
  Future<bool> updateProfile(String genotype, String bloodGroup) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final error = await ProfileService.updateProfile(genotype, bloodGroup);
      if (error == null) {
        await loadProfile(force: true);
      } else {
        _errorMessage = error;
      }
      return error == null;
    } catch (_) {
      _errorMessage = 'Failed to save profile. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear cached state (call on logout).
  void clear() {
    _user = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
