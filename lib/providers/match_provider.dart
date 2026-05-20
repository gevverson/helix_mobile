import 'package:flutter/foundation.dart';
import '../models/match_result.dart';
import '../services/network_guard.dart';
import '../services/profile_service.dart';

/// Manages genetic compatibility check state across the app.
class MatchProvider extends ChangeNotifier {
  MatchResult? _result;
  bool _isChecking = false;
  String? _errorMessage;

  MatchResult? get result => _result;
  bool get isChecking => _isChecking;
  String? get errorMessage => _errorMessage;

  Future<void> checkCompatibility({
    required String userSex,
    required String partnerGenotype,
    String? partnerRhesus,
  }) async {
    _isChecking = true;
    _result = null;
    _errorMessage = null;
    notifyListeners();

    try {
      _result = await ProfileService.checkMatch(
        userSex: userSex,
        partnerProfile: {
          'genotype': partnerGenotype,
          if (partnerRhesus != null) 'rhesus_factor': partnerRhesus,
        },
      );
    } on NetworkOfflineException catch (e) {
      _errorMessage = e.toString();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  void clear() {
    _result = null;
    _isChecking = false;
    _errorMessage = null;
    notifyListeners();
  }
}
