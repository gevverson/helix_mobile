import 'package:flutter/foundation.dart';
import '../models/scan_result.dart';
import '../services/network_guard.dart';
import '../services/profile_service.dart';

/// Manages OCR scan state across the app.
class ScanProvider extends ChangeNotifier {
  ScanResult? _lastScan;
  bool _isScanning = false;
  bool _isSaving = false;
  String? _errorMessage;

  // Cached file for retry-without-picker
  Uint8List? _cachedBytes;
  String? _cachedFileName;

  ScanResult? get lastScan => _lastScan;
  bool get isScanning => _isScanning;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get canRetry => _cachedBytes != null;

  Future<void> scan(Uint8List bytes, String fileName) async {
    _cachedBytes = bytes;
    _cachedFileName = fileName;
    await _runScan(bytes, fileName);
  }

  Future<void> retry() async {
    if (_cachedBytes == null || _cachedFileName == null) return;
    await _runScan(_cachedBytes!, _cachedFileName!);
  }

  Future<void> _runScan(Uint8List bytes, String fileName) async {
    _isScanning = true;
    _lastScan = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ProfileService.scanReport(bytes, fileName);
      if (result != null && result.hasData) {
        _lastScan = result;
      } else {
        _errorMessage = 'Could not read the document. Try a clearer image.';
      }
    } on NetworkOfflineException catch (e) {
      _errorMessage = e.toString();
    } catch (_) {
      _errorMessage = 'Upload failed. Please try again.';
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<bool> saveToProfile() async {
    if (_lastScan == null) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await ProfileService.updateProfile(
        _lastScan!.genotype ?? 'Unknown',
        _lastScan!.bloodGroup ?? 'Unknown',
      );
      if (ok) {
        _lastScan = null;
        _cachedBytes = null;
        _cachedFileName = null;
      } else {
        _errorMessage = 'Failed to save. Please try again.';
      }
      return ok;
    } catch (_) {
      _errorMessage = 'Failed to save. Please try again.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void clear() {
    _lastScan = null;
    _isScanning = false;
    _isSaving = false;
    _errorMessage = null;
    _cachedBytes = null;
    _cachedFileName = null;
    notifyListeners();
  }
}
