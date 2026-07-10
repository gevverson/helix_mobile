import 'dart:convert';
import '../config/app_constants.dart';
import 'api_client.dart';
import 'auth_service.dart';

/// Discovery, likes, and matches for the dating experience.
class DatingService {
  static final _client = ApiClient.instance;

  static Future<Map<String, String>?> _authHeaders() async {
    final token = await AuthService.getToken();
    if (token == null) return null;
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  /// People you might match with: [{ user_id, name, age, photo_url (blurred),
  /// compatibility }]. Returns [] on any error.
  static Future<List<Map<String, dynamic>>> fetchDiscovery() async {
    final headers = await _authHeaders();
    if (headers == null) return [];
    try {
      final res = await _client.get(
        Uri.parse('${AppConstants.baseUrl}/api/v1/discovery'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Like a user. Returns { matched: bool, match: {...}? } or null on error.
  static Future<Map<String, dynamic>?> likeUser(String userId) async {
    final headers = await _authHeaders();
    if (headers == null) return null;
    try {
      final res = await _client.post(
        Uri.parse('${AppConstants.baseUrl}/api/v1/likes/$userId'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Your matches: [{ match_id, user_id, name, age, photo_url, compatibility,
  /// can_unblur, message }]. Returns [] on error.
  static Future<List<Map<String, dynamic>>> fetchMatches() async {
    final headers = await _authHeaders();
    if (headers == null) return [];
    try {
      final res = await _client.get(
        Uri.parse('${AppConstants.baseUrl}/api/v1/matches'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
