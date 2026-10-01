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

  /// People you might match with: [{ user_id, name, age, city, photo_url (blurred),
  /// compatibility }]. Optional filters: [minAge]/[maxAge] (inclusive) and [city]
  /// (coarse, case-insensitive). Returns [] on any error.
  static Future<List<Map<String, dynamic>>> fetchDiscovery({
    int? minAge,
    int? maxAge,
    String? city,
  }) async {
    final headers = await _authHeaders();
    if (headers == null) return [];
    try {
      final params = <String, String>{
        if (minAge != null) 'min_age': '$minAge',
        if (maxAge != null) 'max_age': '$maxAge',
        if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
      };
      final res = await _client.get(
        Uri.parse('${AppConstants.baseUrl}/api/v1/discovery')
            .replace(queryParameters: params.isEmpty ? null : params),
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

  /// People you've blocked: [{ user_id, name }].
  static Future<List<Map<String, dynamic>>> fetchBlocks() async {
    final headers = await _authHeaders();
    if (headers == null) return [];
    try {
      final res = await _client.get(
        Uri.parse('${AppConstants.baseUrl}/api/v1/blocks'),
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

  /// Unblock a user. Returns `true` on success.
  static Future<bool> unblockUser(String userId) async {
    final headers = await _authHeaders();
    if (headers == null) return false;
    try {
      final res = await _client.delete(
        Uri.parse('${AppConstants.baseUrl}/api/v1/blocks/$userId'),
        headers: headers,
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Block a user. Returns `true` on success.
  static Future<bool> blockUser(String userId) async {
    final headers = await _authHeaders();
    if (headers == null) return false;
    try {
      final res = await _client.post(
        Uri.parse('${AppConstants.baseUrl}/api/v1/blocks/$userId'),
        headers: headers,
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Report a user with a reason (+ optional details). Returns `true` on success.
  static Future<bool> reportUser(String userId, String reason, {String? details}) async {
    final headers = await _authHeaders();
    if (headers == null) return false;
    try {
      final res = await _client.post(
        Uri.parse('${AppConstants.baseUrl}/api/v1/reports/$userId'),
        headers: headers,
        body: jsonEncode({'reason': reason, if (details != null && details.isNotEmpty) 'details': details}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// The message thread for a match: [{ id, match_id, sender_id, body, read,
  /// created_at }] oldest-first. Fetching also marks incoming messages read.
  /// Returns `null` on error — distinct from an empty thread, so a failed poll
  /// never wipes the conversation off the screen.
  static Future<List<Map<String, dynamic>>?> fetchMessages(String matchId) async {
    final headers = await _authHeaders();
    if (headers == null) return null;
    try {
      final res = await _client.get(
        Uri.parse('${AppConstants.baseUrl}/api/v1/matches/$matchId/messages'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Send a message in a match thread. Returns the created message, or null on error.
  static Future<Map<String, dynamic>?> sendMessage(String matchId, String body) async {
    final headers = await _authHeaders();
    if (headers == null) return null;
    try {
      final res = await _client.post(
        Uri.parse('${AppConstants.baseUrl}/api/v1/matches/$matchId/messages'),
        headers: headers,
        body: jsonEncode({'body': body}),
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
  /// can_unblur, message, unread_count }]. Returns [] on error.
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
