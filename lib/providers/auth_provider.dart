import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

/// Manages authentication state across the app.
///
/// Screens listen to this provider via `context.watch<AuthProvider>()`
/// instead of making raw API calls themselves.
class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Attempt login. Returns `true` on success.
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await AuthService.login(email, password);
      if (!success) {
        _errorMessage = 'Invalid credentials. Please try again.';
      }
      return success;
    } catch (e) {
      _errorMessage = 'Connection failed. Check your network.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Attempt Google Sign-In. Returns `true` on success.
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await AuthService.signInWithGoogle();
      if (!success) {
        _errorMessage = 'Google Sign-In failed or was cancelled.';
      }
      return success;
    } catch (e) {
      _errorMessage = 'Connection failed. Check your network.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Attempt registration. Returns `true` on success.
  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await AuthService.register(name, email, password);
      if (!success) {
        _errorMessage = 'Registration failed. Email may already be in use.';
      }
      return success;
    } catch (e) {
      _errorMessage = 'Connection failed. Check your network.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear auth token and reset state.
  Future<void> logout() async {
    await AuthService.logout();
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear any displayed error.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
